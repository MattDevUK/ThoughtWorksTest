
provider "google" {
	credentials = "${file("ThoughtWorks-820392232dfa.json")}"
	project     = "flash-span-180315"
	region      = "europe-west1"
}

resource "google_compute_address" "tw-services" {
  name = "pubAddress1"
  region = "europe-west1"
}

resource "google_compute_instance" "default" {
  name         = "ThoughtWorks"
  machine_type = "f1-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1604-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.tw-services.address}"
    }
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  provisioner "local-exec" {
    command = ""
  }

  depends_on = ["google_compute_address.tw-services"]
}