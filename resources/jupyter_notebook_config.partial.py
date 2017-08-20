
# Whether to trust or not X-Scheme/X-Forwarded-Proto and X-Real-Ip/X-Forwarded-
# For headerssent by the upstream reverse proxy. Necessary if the proxy handles
# SSL
#c.NotebookApp.trust_xheaders = True

# Include our extra templates
c.NotebookApp.extra_template_paths = ['/srv/templates/']
