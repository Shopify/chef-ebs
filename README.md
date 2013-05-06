# chef-ebs

This is a cookbook that makes it easy to create/attach EBS volumes, and create
filesystems and RAID arrays on them.


## Usage

Add `recipe[ebs]` to your run list, and configure these attributes:

### RAID Array Creation

Create a RAID 10 across four 10GB volumes, format it with XFS, and mount it on
`/data`.

```ruby
{
  :ebs => {
    :raids => {
      '/dev/md0' => {
        :num_disks => 4,
        :disk_size => 10,
        :raid_level => 10,
        :fstype => 'xfs',
        :mount_point => '/data',
        :uselvm => true,
        :persistent_volumes => [
          "vol-xxxxxxxx",
          "vol-xxxxxxxx",
          "vol-xxxxxxxx",
          "vol-xxxxxxxx"
        ]
      }
    }
  }
}
```

### EBS Volume Creation

Create a 10GB volume, format it with XFS, and mount it on `/data`.

```ruby
{
  :ebs => {
    :volumes => {
      '/data' => {
        :size => 10,
        :fstype => 'xfs'
      }
    }
  }
}
```

## Credentials

Expects a `credentials` databag with an `aws` item that contains `aws_access_key_id` and `aws_secret_access_key`.

You can override the databag and item names with `node[:ebs][:creds][:databag]`, and `node[:ebs][:creds][:item]`, but the key names are static.

## Requirements

- [Opscode AWS Cookbook](https://github.com/opscode-cookbooks/aws)
