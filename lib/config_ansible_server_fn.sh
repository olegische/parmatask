#! /bin/bash

config_ansible_server_fn ( )
{

while read line
do
    if [[ $line == \#* ]]; then continue; fi
    vm_name=$( cut -d ' ' -f2 <<< $line )

    if [[ $vm_name == ansible* ]]; then
        ssh_expect $vm_name 100 "yum install -y expect"
        ssh_expect $vm_name 100 "yum install -y rsync"
        ssh_expect $vm_name 100 "yum install -y epel-release"
        ssh_expect $vm_name 3 "yum repolist | grep epel"
        ssh_expect $vm_name 3 "rpm -qa | grep ansible"
        ssh_expect $vm_name 600 "yum install -y ansible"
        ssh_expect $vm_name 3 "ansible --version"
        ssh_expect $vm_name 3 "hostnamectl set-hostname $vm_name"
        ssh_expect $vm_name 5 "ssh-keygen -f ~/.ssh/id_rsa -q -N ''"
        scp_expect $vm_name "./subscripts/ssh-copy-id_expect.sh" "/tmp"
        scp_expect $vm_name "./passwd/root.$vm_name" "/tmp"


        if [ -f "./tmp/ansible_hosts" ]; then
            rm -f "./tmp/ansible_hosts"
        fi

        while read line2
        do
            if [[ $line2 == \#* ]]; then continue; fi

# Add record about slave to Ansible's /etc/hosts
            expect -c "$( expect_enter_hosts $line2 )"

            tmp_host=$( cut -d ' ' -f2 <<< $line2 )
            if [ $tmp_host = $vm_name ]; then
                unset tmp_host
                continue
            fi
            tmp_passwd=$( cat ./passwd/root.$tmp_host)

            ssh_expect $vm_name 5 "/tmp/ssh-copy-id_expect.sh root $tmp_passwd $tmp_host"
            unset tmp_passwd

            if [[ $tmp_host == jenkins* ]]
            then
                echo '[jenkins]' >> "./tmp/ansible_hosts"
            elif [[ $tmp_host == gitlab* ]]
            then
                echo '[gitlab]' >> "./tmp/ansible_hosts"
            elif [[ $tmp_host == testbox* ]]
            then
                echo '[test]' >> "./tmp/ansible_hosts"
            fi
            echo "$tmp_host" >> "./tmp/ansible_hosts"
            unset tmp_host
        done < "./tmp/hosts"

        if [ -f "./tmp/ansible_hosts" ]; then
            cp "./tmp/ansible_hosts" "./test-ansible/hosts"
            rsync -arv --rsh="sshpass -p $( cat ./passwd/root."$vm_name") ssh -o StrictHostKeyChecking=no -l root"\
                --progress "./tmp/ansible_hosts" root@$vm_name:"/etc/ansible/hosts"
            rm -f "./tmp/ansible_hosts"
        fi
        ssh_expect $vm_name 2 "sed -i 's/#pipelining = False/pipelining = True/g' /etc/ansible/ansible.cfg"
        rsync -arv --rsh="sshpass -p $( cat ./passwd/root."$vm_name") ssh -o StrictHostKeyChecking=no -l root"\
            --progress "./ansible-srv-data/" root@$vm_name:"/etc/ansible"
    fi
# No sanity check for ./tmp/hosts
done < $TMP_HOSTS_FILE_PATH

}