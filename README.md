# Install wp-env
brew install node
brew install --cask docker
npm install -g @wordpress/env

# Start wp-env
wp-env start

http://localhost:8888
Username: admin
Password: password

# Run wp-cli
wp-env run cli wp [command]...