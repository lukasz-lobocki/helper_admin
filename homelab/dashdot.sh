docker container run -it \
  -p 3001:3001 \
  --privileged \
  -v /:/mnt/host:ro \
  --env DASHDOT_ENABLE_CPU_TEMPS="true" \
  --env DASHDOT_SHOW_HOST="true" \
  --env DASHDOT_CUSTOM_HOST="odroid" \
  --env DASHDOT_ALWAYS_SHOW_PERCENTAGES="true" \
  --env DASHDOT_DISABLE_INTEGRATIONS="true" \
  --env DASHDOT_SHOW_DASH_VERSION=icon_hover \
  mauricenino/dashdot
  