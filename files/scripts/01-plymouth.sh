#!/usr/bin/env bash

set -oue pipefail

cd /usr/share/plymouth/themes
curl -L https://github.com/adi1090x/plymouth-themes/releases/download/v1.0/circle.tar.gz | tar xzvf -

cat <<EOF >> circle/circle.script

vauxite_image = Image("/usr/share/plymouth/themes/circle/watermark.png");
vauxite_sprite = Sprite();

vauxite_sprite.SetImage(vauxite_image);
vauxite_sprite.SetX(Window.GetX() + (Window.GetWidth() / 2 - vauxite_image.GetWidth() / 2)); # center the image horizontally
vauxite_sprite.SetY(Window.GetHeight() - vauxite_image.GetHeight() - 50); # display just above the bottom of the screen
EOF

plymouth-set-default-theme circle
