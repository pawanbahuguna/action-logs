FROM alpine

# Install necessary packages (curl and jq)
RUN apk update && apk add --no-cache curl jq

# Copy the entrypoint script to the container
COPY entrypoint.sh /entrypoint.sh

# Make the script executable
RUN chmod +x /entrypoint.sh

# Set the entrypoint to the script
ENTRYPOINT [ "/entrypoint.sh" ]
