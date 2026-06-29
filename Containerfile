FROM harbor.nbt.local/vizor/engagement-service@sha256:9b6be3d712b7f4e08109efa06686c0bcb808e3b7183730f483d4d29909e41970

# Copy fixed YAMLs into the image
COPY . /app/config

