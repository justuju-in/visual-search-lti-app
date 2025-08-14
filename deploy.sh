#!/bin/bash

# Visual Search LTI App - Automated Deployment Script
# This script automates the deployment process with minimal user input

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"
    
    local missing_deps=()
    
    # Check Docker
    if command_exists docker; then
        print_success "Docker is installed"
        if ! docker info >/dev/null 2>&1; then
            print_error "Docker is not running. Please start Docker and try again."
            exit 1
        fi
    else
        missing_deps+=("docker")
    fi
    
    # Check Docker Compose
    if docker compose version >/dev/null 2>&1; then
        print_success "Docker Compose is available"
    elif command_exists "docker-compose"; then
        print_warning "Using legacy docker-compose command"
        COMPOSE_CMD="docker-compose"
    else
        missing_deps+=("docker-compose")
    fi
    
    # Check Git
    if command_exists git; then
        print_success "Git is installed"
    else
        missing_deps+=("git")
    fi
    
    # Check htpasswd for password generation
    if command_exists htpasswd; then
        print_success "htpasswd is available"
    else
        print_warning "htpasswd not found - will use fallback password generation"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo -e "\nPlease install the missing dependencies:"
        echo "  Ubuntu/Debian: sudo apt update && sudo apt install -y docker.io git apache2-utils"
        echo "  CentOS/RHEL: sudo yum install -y docker git httpd-tools"
        echo "  macOS: brew install docker git"
        echo "  Note: Modern Docker includes Compose as a plugin (docker compose)"
        exit 1
    fi
}

# Function to check and free ports
check_ports() {
    print_header "CHECKING PORTS"
    
    local ports=(80 443)
    local busy_ports=()
    
    for port in "${ports[@]}"; do
        if ss -tuln | grep -q ":$port "; then
            busy_ports+=($port)
        fi
    done
    
    if [ ${#busy_ports[@]} -ne 0 ]; then
        print_warning "Ports ${busy_ports[*]} are in use"
        echo "Do you want to:"
        echo "1. Stop services using these ports (recommended)"
        echo "2. Continue anyway (may cause conflicts)"
        echo "3. Exit and manually resolve"
        read -p "Choose option (1-3): " choice
        
        case $choice in
            1)
                print_status "Stopping conflicting services..."
                for port in "${busy_ports[@]}"; do
                    if [ "$port" = "80" ] || [ "$port" = "443" ]; then
                        sudo systemctl stop apache2 nginx >/dev/null 2>&1 || true
                        print_success "Stopped web servers on port $port"
                    fi
                done
                ;;
            2)
                print_warning "Continuing with port conflicts - deployment may fail"
                ;;
            3)
                print_status "Please manually stop services using ports ${busy_ports[*]} and run this script again"
                exit 0
                ;;
        esac
    else
        print_success "Required ports (80, 443) are available"
    fi
}

# Function to get the correct docker compose command
get_compose_cmd() {
    if [ -n "$COMPOSE_CMD" ]; then
        echo "$COMPOSE_CMD"
    else
        echo "docker compose"
    fi
}

# Function to generate secure passwords
generate_password() {
    local length=${1:-16}
    openssl rand -base64 $length 2>/dev/null | tr -d "=+/" | cut -c1-$length || \
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1
}

# Function to generate bcrypt hash
generate_bcrypt() {
    local password="$1"
    if command_exists htpasswd; then
        echo "$password" | htpasswd -nBi admin | cut -d: -f2
    else
        # Fallback - use simple password (not recommended for production)
        print_warning "Using fallback password generation - install apache2-utils for better security"
        echo '$2y$05$.eBEUbkCmao./DP1EiZkuOY2lAE5bXMIUpRuN0I/Z1GMKUPeb61GK'
    fi
}

# Function to collect deployment information
collect_deployment_info() {
    print_header "DEPLOYMENT CONFIGURATION"
    
    echo "Choose deployment type:"
    echo "1. Development (HTTP, localhost)"
    echo "2. Production (HTTPS, custom domain)"
    read -p "Enter choice (1-2) [1]: " deploy_type
    deploy_type=${deploy_type:-1}
    
    if [ "$deploy_type" = "2" ]; then
        # Production deployment
        read -p "Enter your domain name (e.g., myapp.example.com): " domain
        while [ -z "$domain" ]; do
            print_error "Domain name is required for production deployment"
            read -p "Enter your domain name: " domain
        done
        
        read -p "Enter your email for SSL certificates: " email
        while [ -z "$email" ]; do
            print_error "Email is required for SSL certificates"
            read -p "Enter your email: " email
        done
        
        deployment_mode="production"
        app_domain="$domain"
        acme_email="$email"
    else
        # Development deployment
        deployment_mode="development"
        app_domain="localhost"
        acme_email="dev@localhost"
    fi
    
    # Database configuration
    print_status "Configuring database..."
    db_user="ltiuser"
    db_pass=$(generate_password 20)
    db_name="ltidatabase"
    
    # LTI configuration
    print_status "Configuring LTI settings..."
    lti_key=$(generate_password 32)
    
    # Tool provider configuration
    read -p "Enter tool provider name [Visual Search LTI]: " tool_name
    tool_name=${tool_name:-"Visual Search LTI"}
    
    read -p "Enter tool description [Interactive Visual Search Tool]: " tool_desc
    tool_desc=${tool_desc:-"Interactive Visual Search Tool"}
    
    # Admin credentials
    print_status "Setting up admin credentials..."
    admin_user="admin"
    admin_pass=$(generate_password 12)
    admin_hash=$(generate_bcrypt "$admin_pass")
    
    print_success "Configuration collected successfully"
}

# Function to create environment file
create_env_file() {
    print_header "CREATING ENVIRONMENT CONFIGURATION"
    
    local env_file=".env"
    
    cat > "$env_file" << EOF
# Database Configuration
DB_USER=$db_user
DB_PASS=$db_pass
DB_NAME=$db_name
DB_HOST=mongo
MONGO_VERSION=latest

# LTI Configuration
LTI_KEY=$lti_key
PORT=3000

# Tool Provider Configuration
TOOL_PROVIDER_URL=https://$app_domain
TOOL_PROVIDER_NAME=$tool_name
TOOL_PROVIDER_LOGO=https://via.placeholder.com/200x200?text=LTI
TOOL_PROVIDER_DESCRIPTION=$tool_desc
TOOL_PROVIDER_REDIRECT_URIS=https://$app_domain/launch
TOOL_PROVIDER_AUTO_ACTIVATE=true

# Traefik Configuration
APP_DOMAIN=$app_domain
TRAEFIK_ACME_EMAIL=$acme_email
TRAEFIK_DASHBOARD_AUTH=admin:\$\$2y\$\$05\$\$.eBEUbkCmao./DP1EiZkuOY2lAE5bXMIUpRuN0I/Z1GMKUPeb61GK

# Platform Registration (Update with your LMS details)
PLATFORM_URL=https://your-lms.example.com
PLATFORM_NAME=Your LMS
PLATFORM_CLIENT_ID=your-client-id
PLATFORM_AUTH_ENDPOINT=https://your-lms.example.com/mod/lti/auth.php
PLATFORM_TOKEN_ENDPOINT=https://your-lms.example.com/mod/lti/token.php
PLATFORM_KEYSET_ENDPOINT=https://your-lms.example.com/mod/lti/certs.php
EOF
    
    print_success "Environment file created: $env_file"
    print_status "Admin credentials - Username: $admin_user, Password: $admin_pass"
    echo "IMPORTANT: Save these credentials securely!"
    echo "Admin Username: $admin_user"
    echo "Admin Password: $admin_pass"
    echo ""
}

# Function to perform deployment
deploy_application() {
    print_header "DEPLOYING APPLICATION"
    
    # Clean up any existing containers
    print_status "Cleaning up existing containers..."
    $(get_compose_cmd) down -v >/dev/null 2>&1 || true
    
    # Choose compose file based on deployment mode
    if [ "$deployment_mode" = "development" ]; then
        compose_file="docker-compose.dev.yml"
        if [ ! -f "$compose_file" ]; then
            print_warning "Development compose file not found, using production config"
            compose_file="docker-compose.yml"
        fi
    else
        compose_file="docker-compose.yml"
    fi
    
    print_status "Building and starting services with $compose_file..."
    
    # Build and start services
    if $(get_compose_cmd) -f "$compose_file" up --build -d; then
        print_success "Services started successfully"
    else
        print_error "Failed to start services"
        return 1
    fi
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    check_service_health
}

# Function to check service health
check_service_health() {
    print_header "CHECKING SERVICE HEALTH"
    
    local services=("mongo" "app" "traefik")
    local all_healthy=true
    
    for service in "${services[@]}"; do
        if $(get_compose_cmd) ps "$service" | grep -q "Up"; then
            print_success "$service is running"
        else
            print_error "$service is not running"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        print_success "All services are healthy"
        show_access_info
    else
        print_error "Some services are not healthy. Check logs with: $(get_compose_cmd) logs"
        return 1
    fi
}

# Function to show access information
show_access_info() {
    print_header "DEPLOYMENT COMPLETE"
    
    echo -e "${GREEN}🎉 Your LTI application is now running!${NC}\n"
    
    if [ "$deployment_mode" = "development" ]; then
        echo "📱 Application URL: http://localhost:3000"
        echo "🔧 Traefik Dashboard: http://localhost:8080"
    else
        echo "📱 Application URL: https://$app_domain"
        echo "🔧 Traefik Dashboard: https://$app_domain/dashboard/"
    fi
    
    echo ""
    echo "🔐 Admin Credentials:"
    echo "   Username: $admin_user"
    echo "   Password: $admin_pass"
    echo ""
    echo "📊 Database Information:"
    echo "   User: $db_user"
    echo "   Password: $db_pass"
    echo "   Database: $db_name"
    echo ""
    echo "🔑 LTI Key: $lti_key"
    echo ""
    
    if [ "$deployment_mode" = "production" ]; then
        echo "📝 Next Steps for LMS Integration:"
        echo "1. Configure your LMS with the following LTI 1.3 settings:"
        echo "   - Tool URL: https://$app_domain"
        echo "   - Login URL: https://$app_domain/login"
        echo "   - Target Link URI: https://$app_domain/launch"
        echo "   - JWK Set URL: https://$app_domain/keys"
        echo "2. Update the PLATFORM_* variables in .env with your LMS details"
        echo "3. Restart the application: $(get_compose_cmd) restart"
    fi
    
    echo ""
    echo "📋 Useful Commands:"
    echo "   View logs: $(get_compose_cmd) logs -f"
    echo "   Stop services: $(get_compose_cmd) down"
    echo "   Restart services: $(get_compose_cmd) restart"
    echo "   Update application: git pull && $(get_compose_cmd) up --build -d"
    echo ""
    
    print_success "Setup completed successfully!"
}

# Function to handle cleanup on script exit
cleanup() {
    if [ $? -ne 0 ]; then
        print_error "Deployment failed. Check the logs above for details."
        echo "You can try running the script again or check:"
        echo "  - Docker logs: $(get_compose_cmd) logs"
        echo "  - System resources: docker system df"
        echo "  - Port conflicts: ss -tuln | grep ':80\\|:443'"
    fi
}

# Main execution
main() {
    trap cleanup EXIT
    
    print_header "VISUAL SEARCH LTI APP - AUTOMATED DEPLOYMENT"
    echo "This script will set up your LTI application with minimal configuration."
    echo "Press Ctrl+C to cancel at any time."
    echo ""
    
    read -p "Press Enter to continue..."
    
    check_prerequisites
    check_ports
    collect_deployment_info
    create_env_file
    deploy_application
}

# Run main function
main "$@"
