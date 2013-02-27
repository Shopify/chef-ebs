node[:ebs][:volumes].each do |mount_point, options|
  if !options[:device] && options[:size]
    if node[:ebs][:creds][:encrypted]
      credentials = Chef::EncryptedDataBagItem.load(node[:ebs][:creds][:databag], node[:ebs][:creds][:item])
    else
      credentials = data_bag_item node[:ebs][:creds][:databag], node[:ebs][:creds][:item]
    end

    devid = Dir.glob('/dev/xvd?').sort.last[-1,1].succ
    device = "/dev/sd#{devid}"

    vol = aws_ebs_volume device do
      aws_access_key credentials[node.ebs.creds.aki]
      aws_secret_access_key credentials[node.ebs.creds.sak]
      size options[:size]
      device device
      availability_zone node[:ec2][:placement_availability_zone]
      action :nothing
    end
    vol.run_action(:create)
    vol.run_action(:attach)
    node.set[:ebs][:volumes][mount_point][:device] = "/dev/xvd#{devid}"
    node.save
  end
end

node[:ebs][:volumes].each do |mount_point, options|
  execute 'mkfs' do
    command "mkfs -t #{options[:fstype]} #{options[:device]}"
    not_if do
      BlockDevice.wait_for(options[:device])
      system("blkid -s TYPE -o value #{options[:device]}")
    end
  end

  directory mount_point do
    recursive true
    action :create
    mode 0755
  end

  mount mount_point do
    fstype options[:fstype]
    device options[:device]
    options 'noatime'
    action [:mount, :enable]
  end
end
