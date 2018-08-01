require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'reviewday', if: os[:family] == 'ubuntu' do

  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def puppet_manifest
    manifest_path = File.join(pp_path, 'default.pp')
    File.read(manifest_path)
  end

  it 'should work with no errors' do
    apply_manifest(puppet_manifest, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(puppet_manifest, catch_changes: true)
  end

  describe command('su - reviewday -c "cd /var/lib/reviewday/reviewday/ && PYTHONPATH=/var/lib/reviewday/reviewday flock -n /var/lib/reviewday/update.lock python bin/reviewday -o /srv/static/reviewday"') do
    its(:exit_status) { should eq 0 }
  end

  describe command('curl http://localhost/reviews/') do
    its(:stdout) { should contain('OpenStack branch reviews') }
  end

end
