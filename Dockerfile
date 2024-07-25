FROM ubuntu:noble

### Labels
LABEL maintainer="Chris Wieringa <cwieri39@calvin.edu>"
LABEL "org.opencontainers.image.authors"='Chris Wieringa cwieri39@calvin.edu"'
LABEL "com.kasmweb.image"="true"
LABEL "com.kasmweb.gpu_acceleration_egl"="nvidia"

# Set versions and platforms
ARG BUILDDATE=20240725-2
ARG USER=ubuntu
ARG TZ='America/Detroit'

# KasmVNC
ARG BG_IMG=bg_kasm.png
ARG EXTRA_SH=noop.sh
ARG START_PULSEAUDIO=1
ARG START_XFCE4=1

ENV AUDIO_PORT=4901 \
    DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    DISTRO=ubuntu \
    GOMP_SPINCOUNT=0 \
    HOME=/home/kasm-default-profile \
    INST_SCRIPTS=/dockerstartup/install \
    KASMVNC_AUTO_RECOVER=true \
    KASM_VNC_PATH=/usr/share/kasmvnc \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=$TZ \
    LD_LIBRARY_PATH=/opt/libjpeg-turbo/lib64/:/usr/local/lib/ \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}:/usr/local/nvidia/lib:/usr/local/nvidia/lib64 \
    MAX_FRAME_RATE=24 \
    NO_VNC_PORT=6901 \
    NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics,compat32,utility \
    OMP_WAIT_POLICY=PASSIVE \
    PULSE_RUNTIME_PATH=/var/run/pulse \
    SDL_GAMECONTROLLERCONFIG="030000005e040000be02000014010000,XInput Controller,platform:Linux,a:b0,b:b1,x:b2,y:b3,back:b8,guide:b16,start:b9,leftstick:b10,rightstick:b11,leftshoulder:b4,rightshoulder:b5,dpup:b12,dpdown:b13,dpleft:b14,dpright:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:b6,righttrigger:b7" \
    SHELL=/bin/bash \
    START_PULSEAUDIO=$START_PULSEAUDIO \
    STARTUPDIR=/dockerstartup \
    START_XFCE4=$START_XFCE4 \
    TERM=xterm-256color \
    TZ=$TZ \
    VNC_COL_DEPTH=24 \
    VNCOPTIONS="-PreferBandwidth -DynamicQualityMin=4 -DynamicQualityMax=7 -DLP_ClipDelay=0" \
    VNC_PORT=5901 \
    VNC_PORT=5901 \
    VNC_PW=vncpassword \
    VNC_RESOLUTION=1280x1024 \
    VNC_RESOLUTION=1280x720 \
    VNC_VIEW_ONLY_PW=vncviewonlypassword

# Do all run commands with bash
SHELL ["/bin/bash", "-c"] 

##################################
## Start with base Ubuntu
##################################

# Start with some base packages and APT setup
RUN apt update -y && \
    apt install -y \
    apt-transport-https \
    ca-certificates \
    colord \
    curl \
    git \
    gnupg \
    gpg \
    locales \
    lsb-release \
    nano \
    pm-utils \
    software-properties-common \
    tar \
    tofrodos \
    unzip \
    vim \
    vim-nox \
    wget \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Calvin cpscadmin repo keys
RUN echo "deb [signed-by=/usr/share/keyrings/csrepo.gpg] http://cpscadmin.cs.calvin.edu/repos/cpsc-ubuntu/ noble main" | tee -a /etc/apt/sources.list.d/cs-ubuntu-software-noble.list && \
    curl https://cpscadmin.cs.calvin.edu/repos/cpsc-ubuntu/csrepo.asc | tee /tmp/csrepo.asc && \
    gpg --dearmor /tmp/csrepo.asc && \
    mv /tmp/csrepo.asc.gpg /usr/share/keyrings/csrepo.gpg && \
    rm -f /tmp/csrepo.asc

##################################
## Container configuration
##################################

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo "$TZ" > /etc/timezone

# Add CalvinAD trusted root certificate
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/CalvinCollege-ad-CA.crt /etc/ssl/certs/
RUN chmod 0644 /etc/ssl/certs/CalvinCollege-ad-CA.crt && \
    ln -s -f /etc/ssl/certs/CalvinCollege-ad-CA.crt /etc/ssl/certs/ddbc78f4.0

# Add a /scripts directory for class includes
RUN mkdir -p /scripts

##################################
## Container configuration for GUI
##  -- based from 
##     https://github.com/bpmct/coder-templates/blob/main/better-vnc/build/
##     https://github.com/kasmtech/workspaces-core-images/blob/develop/dockerfile-kasm-core
##################################

### Home setup
WORKDIR $HOME
RUN mkdir -p $HOME/Desktop

### Support NVIDIA gpus for graphics acceleration
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
COPY workspaces-core-images/src/ubuntu/install/nvidia/10_nvidia.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json

### Setup package rules
COPY workspaces-core-images/src/ubuntu/install/package_rules $INST_SCRIPTS/package_rules/
RUN bash $INST_SCRIPTS/package_rules/package_rules.sh && rm -rf $INST_SCRIPTS/package_rules/

### Install common tools
COPY workspaces-core-images/src/ubuntu/install/tools $INST_SCRIPTS/tools/
RUN bash $INST_SCRIPTS/tools/install_tools.sh && rm -rf $INST_SCRIPTS/tools/

### Copy over the maximization script to our startup dir for use by app images.
COPY workspaces-core-images/src/ubuntu/install/maximize_script $STARTUPDIR/

### Install custom fonts
# NOTE: I don't need every font/language -- just stick with english and specified noto packages
# COPY workspaces-core-images/src/ubuntu/install/fonts $INST_SCRIPTS/fonts/
# RUN bash $INST_SCRIPTS/fonts/install_custom_fonts.sh && rm -rf $INST_SCRIPTS/fonts/
RUN apt update -y && \
    apt install -y fonts-noto-core \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    language-pack-en

### Install xfce UI
COPY workspaces-core-images/src/ubuntu/install/xfce $INST_SCRIPTS/xfce/
RUN bash $INST_SCRIPTS/xfce/install_xfce_ui.sh && rm -rf $INST_SCRIPTS/xfce/
ADD workspaces-core-images/src/$DISTRO/xfce/.config/ $HOME/.config/
RUN mkdir -p /usr/share/extra/backgrounds/
RUN mkdir -p /usr/share/extra/icons/
ADD workspaces-core-images/src/common/resources/images/bg_kasm.png  /usr/share/backgrounds/bg_kasm.png
ADD workspaces-core-images/src/common/resources/images/$BG_IMG  /usr/share/backgrounds/bg_default.png
ADD workspaces-core-images/src/common/resources/images/icon_ubuntu.png /usr/share/extra/icons/icon_ubuntu.png
ADD workspaces-core-images/src/common/resources/images/icon_ubuntu.png /usr/share/extra/icons/icon_default.png
ADD workspaces-core-images/src/common/resources/images/icon_kasm.png /usr/share/extra/icons/icon_kasm.png
ADD workspaces-core-images/src/common/resources/images/egress_info.svg /usr/share/extra/icons/egress_info.svg
ADD workspaces-core-images/src/common/resources/images/egress_error.svg /usr/share/extra/icons/egress_error.svg
ADD workspaces-core-images/src/common/resources/images/egress_offline.svg /usr/share/extra/icons/egress_offline.svg

### Install kasm_vnc dependencies and binaries
COPY workspaces-core-images/src/ubuntu/install/kasm_vnc $INST_SCRIPTS/kasm_vnc/
RUN bash $INST_SCRIPTS/kasm_vnc/install_kasm_vnc.sh && rm -rf $INST_SCRIPTS/kasm_vnc/
COPY workspaces-core-images/src/common/install/kasm_vnc/kasmvnc.yaml /etc/kasmvnc/

### Install Kasm Profile Sync
COPY workspaces-core-images/src/ubuntu/install/profile_sync $INST_SCRIPTS/profile_sync/
RUN bash $INST_SCRIPTS/profile_sync/install_profile_sync.sh

### Install Kasm Upload Server
COPY workspaces-core-images/src/ubuntu/install/kasm_upload_server $INST_SCRIPTS/kasm_upload_server/
RUN bash $INST_SCRIPTS/kasm_upload_server/install_kasm_upload_server.sh  && rm -rf $INST_SCRIPTS/kasm_upload_server/

### Install Audio
COPY workspaces-core-images/src/ubuntu/install/audio $INST_SCRIPTS/audio/
RUN bash $INST_SCRIPTS/audio/install_audio.sh  && rm -rf $INST_SCRIPTS/audio/

### Install Audio Input
COPY workspaces-core-images/src/ubuntu/install/audio_input $INST_SCRIPTS/audio_input/
RUN bash $INST_SCRIPTS/audio_input/install_audio_input.sh && rm -rf $INST_SCRIPTS/audio_input/

### Install Gamepad Service
COPY workspaces-core-images/src/ubuntu/install/gamepad $INST_SCRIPTS/gamepad/
RUN bash $INST_SCRIPTS/gamepad/install_gamepad.sh && rm -rf $INST_SCRIPTS/gamepad/

### Install Webcam Service
COPY workspaces-core-images/src/ubuntu/install/webcam $INST_SCRIPTS/webcam/
RUN bash $INST_SCRIPTS/webcam/install_webcam.sh && rm -rf $INST_SCRIPTS/webcam/

### Install Printer Service
COPY workspaces-core-images/src/ubuntu/install/printer $INST_SCRIPTS/printer/
COPY workspaces-core-images/src/ubuntu/install/printer/start_cups.sh /etc/cups/start_cups.sh
RUN bash $INST_SCRIPTS/printer/install_printer.sh && rm -rf $INST_SCRIPTS/printer
COPY workspaces-core-images/src/ubuntu/install/printer/resources/*.ppd /etc/cups/ppd/

### Install Recorder Service
COPY workspaces-core-images/src/ubuntu/install/recorder $INST_SCRIPTS/recorder/
RUN bash $INST_SCRIPTS/recorder/install_recorder.sh && rm -rf $INST_SCRIPTS/recorder

### Install custom cursors
COPY workspaces-core-images/src/ubuntu/install/cursors $INST_SCRIPTS/cursors/
RUN bash $INST_SCRIPTS/cursors/install_cursors.sh && rm -rf $INST_SCRIPTS/cursors/

### configure startup
COPY workspaces-core-images/src/common/scripts/kasm_hook_scripts $STARTUPDIR
ADD workspaces-core-images/src/common/startup_scripts $STARTUPDIR
RUN bash $STARTUPDIR/set_user_permission.sh $STARTUPDIR $HOME && \
    echo 'source $STARTUPDIR/generate_container_user' >> $HOME/.bashrc

### extra configurations needed per distro variant
COPY workspaces-core-images/src/ubuntu/install/extra $INST_SCRIPTS/extra/
RUN bash $INST_SCRIPTS/extra/$EXTRA_SH  && rm -rf $INST_SCRIPTS/extra/

### VirtualGL
COPY workspaces-core-images/src/ubuntu/install/virtualgl $INST_SCRIPTS/virtualgl/
RUN bash $INST_SCRIPTS/virtualgl/install_virtualgl.sh && rm -rf $INST_SCRIPTS/virtualgl/

### Sysbox support
COPY workspaces-core-images/src/ubuntu/install/sysbox $INST_SCRIPTS/sysbox/
RUN bash $INST_SCRIPTS/sysbox/install_systemd.sh && rm -rf $INST_SCRIPTS/sysbox/

### Custom Folder Emblems
COPY workspaces-core-images/src/ubuntu/install/emblems $INST_SCRIPTS/emblems/
RUN bash $INST_SCRIPTS/emblems/install_emblems.sh && rm -rf $INST_SCRIPTS/emblems/

### Create user and home directory for base images that don't already define it
RUN (groupadd -g 1000 kasm-user \
    && useradd -M -u 1000 -g 1000 kasm-user \
    && usermod -a -G kasm-user kasm-user) ; exit 0
ENV HOME=/home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

### Create user exclusively for session recording purposes
RUN (groupadd -g 1001 kasm-recorder \
    && useradd -M -u 1001 -g 1001 kasm-recorder \
    && usermod -a -G kasm-recorder) ; exit 0

### FIX PERMISSIONS ## Objective is to change the owner of non-home paths to root, remove write permissions, and set execute where required
# these files are created on container first exec, by the default user, so we have to create them since default will not have write perm
RUN touch $STARTUPDIR/wm.log \
    && touch $STARTUPDIR/window_manager_startup.log \
    && touch $STARTUPDIR/vnc_startup.log \
    && touch $STARTUPDIR/no_vnc_startup.log \
    && chown -R root:root $STARTUPDIR \
    && find $STARTUPDIR -type d -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -exec chmod 644 {} \; \
    && find $STARTUPDIR -type f -iname "*.sh" -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -iname "*.py" -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -iname "*.rb" -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -iname "*.pl" -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -iname "*.log" -exec chmod 666 {} \; \
    && chmod 755 $STARTUPDIR/upload_server/kasm_upload_server \
    && chmod 755 $STARTUPDIR/audio_input/kasm_audio_input_server \
    && chmod 755 $STARTUPDIR/gamepad/kasm_gamepad_server \
    && chmod 755 $STARTUPDIR/webcam/kasm_webcam_server \
    && chmod 755 $STARTUPDIR/printer/kasm_printer_service \
    && chmod 755 $STARTUPDIR/recorder/kasm_recorder_service \
    && chmod 755 $STARTUPDIR/generate_container_user \
    && chmod +x $STARTUPDIR/jsmpeg/kasm_audio_out-linux \
    && rm -rf $STARTUPDIR/install \
    && mkdir -p $STARTUPDIR/kasmrx/Downloads \
    && chown 1000:1000 $STARTUPDIR/kasmrx/Downloads \
    && chown -R root:root /usr/local/bin \
    && chown 1000:root /var/run/pulse \
    && rm -Rf /home/kasm-default-profile/.launchpadlib

### Cleanup job
COPY workspaces-core-images/src/ubuntu/install/cleanup $INST_SCRIPTS/cleanup/
RUN bash $INST_SCRIPTS/cleanup/cleanup.sh && rm -rf $INST_SCRIPTS/cleanup/

##################################
## Calvin CS course requirements
##################################
# CS10X
ADD --chmod=0755 https://raw.githubusercontent.com/Calvin-CS/Infrastructure_devcontainer/main/scripts/CS10X-packages.sh /scripts/CS10X-packages.sh
RUN /scripts/CS10X-packages.sh

# CS112
ADD --chmod=0755 https://raw.githubusercontent.com/Calvin-CS/Infrastructure_devcontainer/main/scripts/CS112-packages.sh /scripts/CS112-packages.sh
RUN /scripts/CS112-packages.sh

# CS212
ADD --chmod=0755 https://raw.githubusercontent.com/Calvin-CS/Infrastructure_devcontainer/main/scripts/CS212-packages.sh /scripts/CS212-packages.sh
RUN /scripts/CS212-packages.sh

# CS214
ADD --chmod=0755 https://raw.githubusercontent.com/Calvin-CS/Infrastructure_devcontainer/main/scripts/CS214-packages.sh /scripts/CS214-packages.sh
RUN /scripts/CS214-packages.sh

# CS262
ADD --chmod=0755 https://raw.githubusercontent.com/Calvin-CS/Infrastructure_devcontainer/main/scripts/CS262-packages.sh /scripts/CS262-packages.sh
RUN /scripts/CS262-packages.sh

# Desktop apps
ADD --chmod=0755 https://raw.githubusercontent.com/Calvin-CS/Infrastructure_devcontainer/main/scripts/desktop-packages.sh /scripts/desktop-packages.sh
RUN /scripts/desktop-packages.sh

##################################
## KasmVNC Coder changes
##################################

# https://github.com/bpmct/coder-templates/blob/main/better-vnc/ modifications
COPY --chmod=0644 kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
COPY --chmod=0755 vnc_startup.sh /dockerstartup/vnc_startup.sh
RUN cp -r /home/kasm-user /tmp/kasm-user

##################################
## Final Container settings
##################################

# add unburden
RUN apt update -y && \
    apt install -y \
    unburden-home-dir && \
    rm -rf /var/lib/apt/lists/*

# add unburden config files
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/unburden-home-dir.conf /etc/unburden-home-dir
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/unburden-home-dir.list /etc/unburden-home-dir.list
ADD https://raw.githubusercontent.com/Calvin-CS/Infrastructure_configs/main/auth/unburden-home-dir /etc/default/unburden-home-dir
RUN chmod 0644 /etc/unburden-home-dir && \
    chmod 0644 /etc/unburden-home-dir.list && \
    chmod 0644 /etc/default/unburden-home-dir && \
    # Add a few more directories that are needed
    echo "m d .config/xfce4 xfce4-config" >> /etc/unburden-home-dir.list

# Cleanup misc files
RUN rm -f /var/log/*.log && \
    rm -f /var/log/apt/* && \
    rm -f /var/log/faillog

# Locale and Environment configuration
RUN locale-gen ${LANG}

# Ports and user
EXPOSE $VNC_PORT \
       $NO_VNC_PORT \
       $UPLOAD_PORT \
       $AUDIO_PORT

USER ${USER}
WORKDIR /home/${USER}
ENTRYPOINT [ "/usr/bin/bash", "-l" ]