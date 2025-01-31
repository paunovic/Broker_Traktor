set -eo pipefail

echo "Input version"
read -r version

tar -cf "release/Broker_Traktor_v$version.zip" --transform='s,^,Broker_Traktor/,' \
  Broker_Traktor.toc traktor.lua TrackingApi.lua embeds.xml lib/* modules/*
