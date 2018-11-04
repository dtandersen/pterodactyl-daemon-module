resource "null_resource" "daemon" {

  provisioner "file" {
    #source      = "firstboot.sh"
    destination = "/tmp/firstboot.sh"
    content     = "${data.template_file.init.rendered}"
  }

  triggers = {
    template = "${md5(data.template_file.init.rendered)}"
  }

  connection {
    type     = "ssh"
    host     = "${var.ssh_host}"
    user     = "${var.ssh_user}"
    password = "${var.ssh_password}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/firstboot.sh",
      "/tmp/firstboot.sh"
    ]
  }
}

data "template_file" "init" {
  template = "${file("${path.module}/firstboot.sh")}"

  vars {
    host = "${var.host}"
    email = "${var.email}"
  }
}
