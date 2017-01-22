FROM ubuntu:latest
#FROM phusion/baseimage:latest
#FROM blitznote/debootstrap-amd64:16.10
ADD script_*.sh /
RUN chown root:root /script_*.sh && chmod 540 /script_*.sh && sync && /script_init.sh
