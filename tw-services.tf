variable "image_name" { 
  type = "string"
  default = "thoughtworks-1505923612"
}

# Set provider
provider "google" {
	credentials = "${file("ThoughtWorks-820392232dfa.json")}"
	project     = "flash-span-180315"
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
  machine_type = "f1-micro"
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

  metadata {
    quotes_ip = "${google_compute_instance.quotes.network_interface.0.address}"
    newsfeeds_ip = "${google_compute_instance.newsfeed.network_interface.0.address}"
  }

#  provisioner "remote-exec" {
#    in"echo '{\"thoughtworks\": {\"service_name\": \"front-end\"}}' > /tmp/run_list.json",
#      chef-client -j /tmp/run_list.json -z --config-option cookbook_path=/tmp/tw-repo/cookbooks -r 'recipe[thoughtworks::deploy]'"
#    ]
#  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  depends_on = ["google_compute_address.tw-services","google_compute_firewall.front-end","google_compute_instance.quotes","google_compute_instance.newsfeed"]
}

# Create Quotes Instance
resource "google_compute_instance" "quotes" {
  name         = "quotes"
  machine_type = "f1-micro"
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
    user = "ubuntu"
    private_key = "${file("/home/matt/.ssh/id_rsa")}"
  }

  provisioner "file" {
    destination = "/tmp/run_list.json"
    content = "{\"thoughtworks\": {\"service_name\": \"quotes\"}}"
  }
  provisioner "remote-exec" {
    inline = [
      "chef-client -j /tmp/run_list.json -z --config-option cookbook_path=/home/ubuntu/tw-repo/cookbooks -r 'recipe[thoughtworks::deploy]'"
    ]
  }
}

# Create Newsfeed Instance
resource "google_compute_instance" "newsfeed" {
  name         = "newsfeed"
  machine_type = "f1-micro"
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

#  provisioner "remote-exec" {
#    inline = [
#      "echo '{\"thoughtworks\": {\"service_name\": \"newsfeed\"}}' > /tmp/run_list.json",
#      chef-client -j /tmp/run_list.json -z --config-option cookbook_path=/tmp/tw-repo/cookbooks -r 'recipe[thoughtworks::deploy]'"
#    ]
#  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}