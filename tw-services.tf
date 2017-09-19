
provider "google" {
	credentials = "${file("ThoughtWorks-820392232dfa.json")}"
	project     = "flash-span-180315"
	region      = "europe-west1"
}

resource "google_compute_address" "tw-services" {
  name = "servicesaddress1"
  region = "europe-west1"
}

resource "google_compute_firewall" "frontend" {
  name    = "frontend-firewall"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_tags = ["frontend"]
}

resource "google_compute_instance" "frontend" {
  name         = "frontend"
  machine_type = "f1-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "thoughtworks-1505827979"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.tw-services.address}"
    }
  }

  tags = ["frontend"]

  metadata {
    quotes_ip = "${google_compute_instance.quotes.network_interface.0.address}"
    newsfeeds_ip = "${google_compute_instance.newsfeeds.network_interface.0.address}"
  }

  metadata_startup_script = "export QUOTE_SERVICE_URL=${google_compute_instance.frontend.metadata.quotes_ip};export NEWSFEED_SERVICE_URL=${google_compute_instance.frontend.metadata.newsfeeds_ip}"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  depends_on = ["google_compute_address.tw-services","google_compute_firewall.frontend","google_compute_instance.quotes","google_compute_instance.newsfeeds"]
}

resource "google_compute_instance" "quotes" {
  name         = "quotes"
  machine_type = "f1-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "thoughtworks-1505827979"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  depends_on = ["google_compute_address.tw-services"]
}

resource "google_compute_instance" "newsfeed" {
  name         = "newsfeed"
  machine_type = "f1-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "thoughtworks-1505827979"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  depends_on = ["google_compute_address.tw-services"]
}