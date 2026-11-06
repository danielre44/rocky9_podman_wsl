
FROM docker.io/library/rockylinux:9 AS rocky9_podman_wsl

# Allow container image docs
RUN sed -i '/^tsflags=nodocs/d' /etc/dnf/dnf.conf

# Setup containers for podman/buildah
RUN dnf -y install \
        systemd \
        dbus-broker \
        sudo \
        podman \
        buildah \
        skopeo \
        crun \
        fuse-overlayfs \
        slirp4netns \
        passt \
        procps-ng \
        iproute \
        which \
        vim-enhanced \
        git \
        unzip \
        openssh-clients \
        bash-completion \
        man-db \
        man-pages \
        glibc-langpack-en \
        dnf-plugins-core && \
    dnf clean all && rm -rf /var/cache/dnf
 
# User with passwordless sudo + subordinate IDs for rootless podman
RUN useradd -m -G wheel -s /bin/bash "dan" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USERNAME}" && \
    chmod 0440 "/etc/sudoers.d/${USERNAME}" && \
    { grep -q "^dan:" /etc/subuid || echo "dan:100000:65536" >> /etc/subuid; } && \
    { grep -q "^dan:" /etc/subgid || echo "dan:100000:65536" >> /etc/subgid; }
 
# Rootless podman needs newuidmap/newgidmap to be setuid or have file caps.
# Tar export/import drops file caps (xattrs) but keeps the setuid bit.
RUN chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap
 
# WSL config: systemd on, default user, and make / a shared mount at boot
RUN printf '%s\n' \
      '[boot]' \
      'systemd=true' \
      'command = "mount --make-rshared /"' \
      '' \
      '[user]' \
      'default=dan' \
      '' \
      '[network]' \
      'hostname=rocky9' \
      '' \
      '[interop]' \
      'appendWindowsPath=true' \
      > /etc/wsl.conf
 
# Fresh machine-id generated on first boot of each imported copy
RUN truncate -s 0 /etc/machine-id && rm -f /var/lib/dbus/machine-id
