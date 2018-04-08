# Mounts volumes defined in attributes to this instance before attempting to
# create defined ebs volumes and raid devices

Chef::Log.fatal!("There are no persistent raid volumes are not defined in the #{node.chef_environment}", \
                 1) if ! node['ebs']['raids'].find{|k0,v0| k0 == 'persistent_volumes'}.nil?

include_recipe "aws"
# get aws credentials
if !node[:ebs][:creds][:iam_roles]
  aws = data_bag_item(node['ebs']['creds']['databag'], node['ebs']['creds']['item'])
else
  aws = nil
end

devices = Dir.glob('/dev/xvd*')
if devices.empty?
  next_mount = "f"
else
  next_mount = devices.map{ |x| x[0,9] }.uniq.sort.last[-1,1].succ
  next_mount = 'f' unless next_mount >= 'f'
end
next_mount.gsub!("xvd","sd")

# Mount all of the ebs volumes defined
node['ebs']['raids'].each do |k,v|
  if v['persistent_volumes']
    disks = []
    v['persistent_volumes'].each do |thisvol|
      if node['aws'] && node['aws']['ebs_volume'] && !node['aws']['ebs_volume'].find{|k1,v1| v1['volume_id'] == thisvol}.nil?
        Chef::Log.info("EBS Volume #{thisvol} is already attached. Skipping...")
        disks << mount = node['aws']['ebs_volume'].find{|k2,v2| v2['volume_id'] == thisvol}.first
      else
        disks << mount = "/dev/sd#{next_mount}"
        next_mount.succ!
        Chef::Log.info("Attaching #{thisvol} to #{mount}")
        aws_ebs_volume mount do
          aws_access_key aws['aws_access_key_id'] if aws
          aws_secret_access_key aws['aws_secret_access_key'] if aws
          device mount
          volume_id thisvol
          action :nothing
        end.run_action(:attach)
      end
    end
    disks.uniq!
    Chef::Log.info("Adding the following disks to #{k}: #{disks.join(" ")}")
    node.set['ebs']['raids'][k]['disks'] = disks.map { |d| d.sub('/sd', '/xvd') } if !disks.empty?
  end
end

include_recipe "ebs"
