variable "credentials_file" {
  type = "string"
  default = "./ThoughtWorks-820392232dfa.json"
}
variable "project_id" {
  type = "string"
  default = "flash-span-180315"
}
variable "remote_user" {
  type = "string"
  default = "ubuntu"
}
variable "image_name" { 
  type = "string"
}
variable "private_ssh_key_file" {
  type = "string"
  default = "~/.ssh/id_rsa"
}
variable "machine_type" {
  type = "string"
  default = "f1-micro"
}
variable "newsfeed_api_token" {}

# Set provider
provider "google" {
	credentials = "${file("${var.credentials_file}")}"
	project     = "${var.project_id}"
	region      = "europe-west1"
}

# Reserve a static public IP for the front-end
resource "google_compute_address" "tw-services" {
  name = "servicesaddress1"
  region = "europe-west1"
}

# Create firewall rules for the front-end
resource "google_compute_firewall" "front-end" {
  name    = "front-end-firewall"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags = ["front-end"]
}

# Create the front-end instance
resource "google_compute_instance" "front-end" {
  name         = "front-end"
  machine_type = "${var.machine_type}"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "${var.image_name}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.tw-services.address}"
    }
  }

  tags = ["front-end"]

  connection {
    user = "${var.remote_user}"
    private_key = "${file("${var.private_ssh_key_file}")}"
  }

  provisioner "file" {
    destination = "/tmp/run_list.json"
    content = "{\"thoughtworks\": {\"service_name\": \"front-end\", \"quotes_ip\": \"${google_compute_instance.quotes.network_interface.0.address}\", \"newsfeed_ip\": \"${google_compute_instance.newsfeed.network_interface.0.address}\", \"newsfeed_api_token\": \"${var.newsfeed_api_token}\"}}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chown -R u${var.remote_user}:${var.remote_user} /home/${var.remote_user}/tw-repo",
      "sudo chef-client -j /tmp/run_list.json -z --config-option cookbook_path=/home/${var.remote_user}/tw-repo/cookbooks -r 'recipe[thoughtworks::deploy]'"
    ]
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  depends_on = ["google_compute_address.tw-services","google_compute_firewall.front-end","google_compute_instance.quotes","google_compute_instance.newsfeed"]

}

# Create Quotes Instance
resource "google_compute_instance" "quotes" {
  name         = "quotes"
  machine_type = "${var.machine_type}"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "${var.image_name}"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  
  connection {
    user = "${var.remote_user}"
    private_key = "${file("${var.private_ssh_key_file}")}"
  }

  provisioner "file" {
    destination = "/tmp/run_list.json"
    content = "{\"thoughtworks\": {\"service_name\": \"quotes\"}}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chown -R ${var.remote_user}:${var.remote_user} /home/${var.remote_user}/tw-repo",
      "sudo chef-client -j /tmp/run_list.json -z --config-option cookbook_path=/home/${var.remote_user}/tw-repo/cookbooks -r 'recipe[thoughtworks::deploy]'"
    ]
  }
}

# Create Newsfeed Instance
resource "google_compute_instance" "newsfeed" {
  name         = "newsfeed"
  machine_type = "${var.machine_type}"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "${var.image_name}"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  connection {
    user = "${var.remote_user}"
    private_key = "${file("${var.private_ssh_key_file}")}"
  }

  provisioner "file" {
    destination = "/tmp/run_list.json"
    content = "{\"thoughtworks\": {\"service_name\": \"newsfeed\"}}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chown -R ${var.remote_user}:${var.remote_user} /home/${var.remote_user}/tw-repo",
      "sudo chef-client -j /tmp/run_list.json -z --config-option cookbook_path=/home/${var.remote_user}/tw-repo/cookbooks -r 'recipe[thoughtworks::deploy]'"
    ]
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

output "front-end-public-ip" {
  value = "${google_compute_address.tw-services.address}:8080"
}
output "front-end-private-ip" {
  value = "${google_compute_instance.front-end.network_interface.0.address}"
}
output "quotes-public-ip" {
  value = "${google_compute_instance.quotes.network_interface.0.access_config.0.assigned_nat_ip}"
}
output "quotes-private-ip" {
  value = "${google_compute_instance.quotes.network_interface.0.address}"
}
output "newsfeed-public-ip" {
  value = "${google_compute_instance.newsfeed.network_interface.0.access_config.0.assigned_nat_ip}"
}
output "newsfeed-private-ip" {
  value = "${google_compute_instance.newsfeed.network_interface.0.address}"
}