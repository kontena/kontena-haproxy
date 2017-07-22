# Kontena HAProxy

HAProxy image that does load-balancing between configured addresses. HAProxy reconfigures itself automatically when backend dns address change.

## Configuration

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| MODE                 | http | Mode of load balancing. Possible values: http, tcp |
| FRONTEND_PORT        | 80      | Port to listen. If `SSL_CERT` is set, will also bind to port 443. |
| BACKENDS             |         | Comma separated list of backends to use, example: app1.foo.com:8080,app2.bar.com:8181 |
| BALANCE              | roundrobin | Load balancing algorithm to use. Possible values include: roundrobin, static-rr, source, leastconn. |
| MAXCONN              | 4096 | Sets the maximum per-process number of concurrent connections. |
| OPTION              | redispatch, forwardfor | Extra options (comma separated list). |
| TIMEOUT              | connect 5000, client 50000, server 50000 | Connect options. |
| POLLING_INTERVAL     | 10 | How often backend addresses are polled (resolved). |
| VIRTUAL_HOSTS        |        | Comma separated list of virtual_host=backend mappings, for example app1=www.domain.com,app2=www.bar.com |
| SSL_CERT             |        | Ssl cert, a pem file with private key followed by public certificate, '\n'(two chars) as the line separator. |


## License

Kontena software is open source, and you can use it for any purpose, personal or commercial. Kontena is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full license text.
