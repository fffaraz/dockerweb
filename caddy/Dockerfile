FROM golang:latest
ENTRYPOINT ["/script_run.sh"]
ADD script_*.sh /
RUN chown root:root /script_*.sh && chmod 544 /script_*.sh && sync && /script_init.sh
