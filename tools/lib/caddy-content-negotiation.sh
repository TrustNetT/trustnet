#!/bin/bash
# caddy-content-negotiation.sh - Setup content negotiation for RPC and API endpoints
# Determines HTML vs JSON response based on client type (browser vs API client)

# This script updates the Caddyfile to serve HTML for browsers and JSON for API clients

cat > /tmp/Caddyfile << 'CADDY_EOF'
# TrustNet Caddy Configuration with Content Negotiation
# Serves HTML for browsers, JSON for API clients

# Web UI - serves static content
:443 trustnet.local {
    root * /var/www/trustnet
    file_server
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
}

# RPC endpoint with content negotiation
rpc.trustnet.local:443 {
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
    
    # Root path - serve HTML or JSON based on Accept header
    @browser {
        header Accept *text/html*
    }
    
    @html_user_agent {
        header User-Agent *Mozilla*
        header User-Agent *Chrome*
        header User-Agent *Safari*
        header User-Agent *Firefox*
        header User-Agent *Edge*
    }
    
    @api_client {
        header User-Agent *curl*
        header User-Agent *wget*
        header User-Agent *python*
        header User-Agent *go-http-client*
        header User-Agent *Postman*
    }
    
    handle / {
        # If browser or HTML request
        @is_browser {
            header Accept *text/html*
        }
        
        handle @is_browser {
            file_server root /var/www/trustnet-caddy {
                roots /var/www/trustnet-caddy
            }
        }
        
        # Default: reverse proxy to backend (serves JSON)
        reverse_proxy http://127.0.0.1:26657 {
            header_uri Host localhost
        }
    }
    
    # All other paths go to RPC backend
    handle /* {
        reverse_proxy http://127.0.0.1:26657 {
            header_uri Host localhost
        }
    }
}

# REST API endpoint with content negotiation
api.trustnet.local:443 {
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
    
    # Root path - serve HTML for browsers
    handle / {
        @is_browser {
            header Accept *text/html*
        }
        
        handle @is_browser {
            file_server root /var/www/trustnet-caddy {
                roots /var/www/trustnet-caddy
            }
        }
        
        # Default: return 404 or stats (API root typically has no content)
        respond "API endpoint ready" 200 {
            header Content-Type application/json
        }
    }
    
    # All API paths go to REST API backend
    handle /* {
        reverse_proxy http://127.0.0.1:1317 {
            header_uri Host localhost
        }
    }
}
CADDY_EOF

echo "✓ Caddy content negotiation configuration created"
echo "  Location: /tmp/Caddyfile"
