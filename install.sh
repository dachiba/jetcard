#!/bin/bash

set -e

password='jetson'

# Record the time this script starts
date

# Get the full dir name of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Keep updating the existing sudo time stamp
sudo -v
while true; do sudo -n true; sleep 120; kill -0 "$$" || exit; done 2>/dev/null &

# Enable i2c permissions
echo "\e[100m Enable i2c permissions \e[0m"
sudo usermod -aG i2c $USER

# Make swapfile
echo "\e[46m Make swapfile \e[0m"
cd
if [ ! -f /var/swapfile ]; then
	sudo fallocate -l 6G /var/swapfile
	sudo chmod 600 /var/swapfile
	sudo mkswap /var/swapfile
	sudo swapon /var/swapfile
	sudo bash -c 'echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab'
else
	echo "Swapfile already exists"
fi

# Install package
echo "\e[46m Install package \e[0m"
sudo apt update
sudo apt install -y python3-pip python3-smbus cmake
sudo apt install -y libhdf5-serial-dev hdf5-tools libhdf5-dev zlib1g-dev zip libjpeg8-dev
sudo apt install -y libopenblas-base
sudo apt install -y liblapack-dev libatlas-base-dev gfortran
sudo apt install -y libfreetype6-dev
sudo apt install -y nodejs npm
sudo apt install -y python-setuptools

# Install nodejs stable
echo "\e[48;5;172m IInstall nodejs stable \e[0m"
sudo npm cache clean
sudo npm install n -g
sudo n stable
hash -r
sudo npm update -g npm

# Install pip and some python dependencies
echo "\e[104m Install pip and some python dependencies \e[0m"
sudo -H pip3 install -U pip
sudo -H pip3 install -U Flask==1.1.1
sudo -H pip3 install -U Pillow==6.2.2

# Install jtop pip wheel
echo "\e[100m Install jtop pip wheel \e[0m"
sudo -H pip install jetson-stats 

# Install the pre-built TensorFlow pip wheel
echo "\e[48;5;202m Install the pre-built TensorFlow pip wheel \e[0m"
sudo -H pip3 install -U testresources setuptools
sudo -H pip3 install -U numpy==1.16.6 future==0.17.1 mock==3.0.5 h5py==2.9.0 keras_preprocessing==1.0.5 keras_applications==1.0.8 gast==0.2.2 enum34 futures protobuf
sudo -H pip3 install --pre --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v43 tensorflow-gpu==2.0.0+nv19.12

# Install the pre-built PyTorch pip wheel 
echo "\e[45m Install the pre-built PyTorch pip wheel  \e[0m"
cd
wget https://nvidia.box.com/shared/static/ncgzus5o23uck9i5oth2n8n06k340l6k.whl -O torch-1.4.0-cp36-cp36m-linux_aarch64.whl
sudo -H pip3 install -U Cython==0.29.15
sudo -H pip3 install -U torch-1.4.0-cp36-cp36m-linux_aarch64.whl

# Install torchvision package
echo "\e[45m Install torchvision package \e[0m"
git clone https://github.com/pytorch/vision
cd vision
git checkout v0.5.0
sudo python3 setup.py install

# Install Scipy pip wheel
echo "\e[45m Install Scipy pip wheel \e[0m"
sudo -H pip3 install -U scipy==1.2.3

# Install scikit-learn pip wheel
echo "\e[45m Install scikit-learn pip wheel \e[0m"
sudo -H pip3 install -U scikit-learn==0.21.3

# Install Pandas pip wheel
echo "\e[45m Install Pandas pip wheel \e[0m"
sudo -H pip3 install -U pandas==0.25.3 matplotlib==3.1.3 seaborn==0.10.0

# Install Chainer pip wheel
echo "\e[45m Install Chainer pip wheel \e[0m"
sudo -H pip3 install -U fastrlock==0.4 cupy==7.2.0 chainer==7.2.0

# Install traitlets (master, to support the unlink() method)
echo "\e[48;5;172m Install traitlets \e[0m"
sudo -H pip3 install git+https://github.com/ipython/traitlets@master

# Install Jupyter Lab
echo "\e[48;5;172m Install Jupyter Lab \e[0m"
sudo -H pip3 install -U jupyter jupyterlab
sudo jupyter labextension install @jupyter-widgets/jupyterlab-manager

jupyter lab --generate-config
python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"

# Install jetcard
echo "\e[44m Install jetcard \e[0m"
cd $DIR
pwd
sudo python3 setup.py install

# Install jetcard display service
echo "\e[44m Install jetcard display service \e[0m"
python3 -m jetcard.create_display_service
sudo mv jetcard_display.service /etc/systemd/system/jetcard_display.service
sudo systemctl enable jetcard_display
sudo systemctl start jetcard_display

# Install jetcard jupyter service
echo "\e[44m Install jetcard jupyter service \e[0m"
python3 -m jetcard.create_jupyter_service
sudo mv jetcard_jupyter.service /etc/systemd/system/jetcard_jupyter.service
sudo systemctl enable jetcard_jupyter
sudo systemctl start jetcard_jupyter

# Install TensorFlow models repository
echo "\e[48;5;202m Install TensorFlow models repository \e[0m"
cd
url="https://github.com/tensorflow/models"
tf_models_dir="TF-models"
if [ ! -d "$tf_models_dir" ] ; then
	git clone $url $tf_models_dir
	cd "$tf_models_dir"/research
	git checkout 5f4d34fc
	wget -O protobuf.zip https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/protoc-3.7.1-linux-aarch_64.zip
	unzip protobuf.zip
	./bin/protoc object_detection/protos/*.proto --python_out=.
	sudo python3 setup.py install
	cd slim
	sudo python3 setup.py install
fi

# Install jupyter_clickable_image_widget
echo "\e[42m Install jupyter_clickable_image_widget \e[0m"
cd
git clone https://github.com/jaybdub/jupyter_clickable_image_widget
cd jupyter_clickable_image_widget
git checkout no_typescript
sudo pip3 install -e .
sudo jupyter labextension install js
cd

# Upgrade package
echo "\e[42m Upgrade package \e[0m"
sudo apt update
sudo apt -y upgrade
sudo apt autoremove -y --purge
sudo apt clean

echo "\e[42m All done! \e[0m"

#record the time this script ends
date
