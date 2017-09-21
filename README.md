# README
This solution was designed to use multiple technologies that I have never used before, to enforce learning under pressure.

### The technologies used:
 - Google Compute Cloud (https://cloud.google.com) *
 - Packer (https://www.packer.io/)*
 - Terraform (https://www.terraform.io/) *
 - Chef
 - Ubuntu
 \* = new technologies learned for this project

### Assumptions:
This solution assumes that:
 - You have a Google Compute account.
 - You are running these commands from within this extracted archive.
 - You have downloaded your service account key file and placed at the root of this directory (https://console.cloud.google.com/apis/credentials).
 - You have added your SSH key against the desired user on the remote machine. (Default: `ubuntu`) (https://console.cloud.google.com/compute/metadata/sshKeys)
 - You have placed the provided Chef repo in the location: `./tw-repo`
 - You are running on a Linux machine and your local private SSH key is located at `~/.ssh/id_rsa`
 - You know the project name for your Google Compute project.

### Directions:
##### Provisioning:
 * Start off by extracting the archive and making sure Packer and Terraform are both installed.
 * We use Packer to build on top of a base Ubuntu image, to create our desired environment for running the applications within.
 * Packer accepts multiple custom variable overrides:
   - `chef_repo_path`: The path to the included Chef Repo (Default: `"~/ThoughtWorks/tw-repo"`)
   - `remote_user`: The user to be used to set up the remote instance.
   - `account_file_path`: The path to the account service file. (Default: `./ThoughtWorks-Service.json`)
   - `machine_type`: The instance type to use. (Default: `f1-micro`)
   - `project_id`: The name of the Google Compute Project to use.
 * Create the image by using the `packer build` command on the packer config file: `packer build packer.json` 
   - You can set variables by defining them after the command: `packer build -var 'chef_repo_path=foo' -var 'project_id=bar' packer.json`
  - This will fire up an instance on Google Cloud, make the neccessary changes to it, then save it as a new image, ready to be passed onto Terraform to create the infrastructure.
  - The created image name will be displayed on the very last line of the Packer output.
  - This will need to be run everytime you want to update the base image, or make a change to the Chef code.
 
##### Infrastructure creation:
 * Once Packer has completed, we will need to run Terraform to create the instances required, deploy the code and start the services.
 *  Terraform also takes multiple variable overrides, some shared with Packer, so keep those the same:
    - `credentials_file`: The path to the account service file. (Default: `./ThoughtWorks-Service.json`)
    - `project_id`: The name of the Google Compute Project to use.
    - `remote_user`: The user to be used on the remote instance. (Default: `ubuntu`)
    - `image_name`: The name of the image created by Packer.
    - `private_ssh_key_file`: The path to the private SSH key associated with your Google Cloud instance.
    - `machine_type`: The instance type to use. (Default: `f1-micro`)
    - `newsfeed_api_token`: The API token to be set for communication between the front-end service and the newsfeed service.
 * You can view a breakdown of what steps Terraform will perform by using the `terraform plan` command. 
   - You will need to specify any variables without a default value in this command. They are set the same way as with Packer: `terraform plan -var 'credentials_file=./ThoughtWorks.json' -var 'remote_user=ubuntu'`
 * When you are happy with the proposed actions, swap out "plan" for "apply" in the exact same command to perform the actions.
 * When Terraform has completed, it will display the public and private IP addresses of the machines created. This is to allow you to easily access the machines to provision the latest version of the code from GitHub.

##### Redeploying:
 * If you make a change to the GitHub project code and wish to update the machines:
   - Decide which machines need updating, one, some or all.
   - For each machine, SSH onto the machine using the username and key you previously provided to Terraform (Or you can use the Google Compute Console to access the machines via a web browser)
   - When on the machine to update, as they are provisioned using Chef, just run the following Chef command: `sudo chef-client -j /tmp/run_list.json -z --config-option cookbook_path=~/tw-repo/cookbooks`
   - This will execute a Chef run, that will check all the dependencies are still installed, it will sync the Git repo, if there are any changes, it will build clean versions of the applications and then deploy them and restart the running services. If there are no changes in Git, it will quietly and quickly run through the cookbook and not make any alterations.

# Future Plans
* To extend this solution to fit in a CI/CD pipeline:
  - Hook up the Packer job to any code hooks from the Chef source code.
  - Implement some form of artefact repository such as Hashicorp Atlas to store the Packer-made images.
  - Include tests in the deployment before replacing existing services.
  - Make sure all Dev teams could feedback into what is required on the base images, such as specific software or versions, i.e. Java versions, etc.
  - Make sure all teams use the images created by Packer to develop on, this keeps everyone working in the same environment and makes for less surprises when trying to deploy something created in a slightly different env.
  - Extrapolate the Chef command to update the services into something more accessible to developers who may not need or want to access the instance directly.
  - Add in the ability to automatically tear down the machines once tests have been run.
* To extend thus solution to production environment:
  - Use the images created by Packer to keep the bas eenvironment the same across dev and production.
  - Only deploy the prebuilt packages to the production systems, as building them on the box takes time and leaves the sourcecode on the machines, which could be a security risk.
  - Bake monitoring solutions into the base image, to monitor basic stats such as box utilisations, generic ones and the app specific ones can be added when the machine is created with an actual role.
  - Deploy the applications behind some form of load balancer, Nginx, Apache, HAProxy or one of the Cloud Vendor's specific ones. To deal with traffic without publicly exposing the services and to deal with SSL termination.
  - Deploy the applications into some form of autoscaling group (AWS terminology), or build out a system using Kubernetes, etc. To deal with load increases.
  - Move my SSH key setup away from the account-level and to the instance level for better security.
  - Deploy the instances inside of a VPC to ensure extra security.
  - Disable public SSH access and only allow through a Bastion host.
  - Utilise Packer to build images for multiple cloud vendors at the same time to allow ability to run on multiple vendors for availability and stability.







PACKER: packer build -var 'chef_repo_path=./tw-repo' -var 'remote_user=ubuntu' -var 'account_file_path=./ThoughtWorks-Service.json' -var 'machine_type=f1-micro' -var 'project_id=flash-span-180315' packer.json

TERRAFORM: terraform plan -var 'credentials_file=./ThoughtWorks-Service.json' -var 'project_id=flash-span-180315' -var 'remote_user=ubuntu' -var 'image_name=thoughtworks-1506026684' -var 'private_ssh_key_file=~/.ssh/id_rsa' -var 'machine_type=n1-standard-1' -var 'newsfeed_api_token=T1&eWbYXNWG1w1^YGKDPxAWJ@^et^&kX'

CHEF: sudo chef-client -j /tmp/run_list.json -z --config-option cookbook_path=~/tw-repo/cookbooks