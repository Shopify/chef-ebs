node[:ebs][:volumes].each do |mount_point, options|
  if !options[:device] && options[:size]
    credentials = Chef::EncryptedDataBagItem.load(node[:ebs][:creds][:databag], node[:ebs][:creds][:item])
    devid = Dir.glob('/dev/xvd?').sort.last[-1,1].succ
    device = "/dev/sd#{devid}"

    vol = aws_ebs_volume device do
      aws_access_key credentials['access_key_id']
      aws_secret_access_key credentials['secret_access_key']
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
