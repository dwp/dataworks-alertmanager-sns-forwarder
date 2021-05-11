FROM datareply/alertmanager-sns-forwarder:0.2

COPY entrypoint.sh .
RUN chmod u+x entrypoint.sh

EXPOSE 9087
ENTRYPOINT ["./entrypoint.sh"]
