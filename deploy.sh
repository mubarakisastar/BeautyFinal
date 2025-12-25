#!/bin/bash

# Beauty API Quick Deploy Script

set -e

echo "🚀 Beauty API Docker Deployment Helper"
echo "========================================"

# Check Docker installation
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

echo "✅ Docker found: $(docker --version)"

# Container management functions
case "${1:-help}" in
    build)
        echo ""
        echo "📦 Building Docker image..."
        docker build -t beauty-api:latest .
        echo "✅ Build complete!"
        echo ""
        echo "Image size: $(docker images beauty-api --format='{{.Size}}')"
        ;;
    
    run)
        echo ""
        echo "🏃 Starting container..."
        CONTAINER_ID=$(docker run -d -p 8000:8000 --name beauty-api-prod beauty-api:latest)
        echo "✅ Container started: $CONTAINER_ID"
        echo ""
        echo "Waiting for API to be ready..."
        sleep 5
        
        # Test health
        if curl -s http://localhost:8000/health > /dev/null; then
            echo "✅ API is healthy!"
            echo ""
            echo "🌐 API accessible at: http://localhost:8000"
            echo "📊 Health check: http://localhost:8000/health"
            echo ""
            echo "Stop with: docker stop beauty-api-prod"
            echo "Logs: docker logs beauty-api-prod -f"
        else
            echo "⚠️  API not responding. Check logs:"
            docker logs beauty-api-prod
        fi
        ;;
    
    stop)
        echo ""
        echo "⏹️  Stopping container..."
        docker stop beauty-api-prod
        docker rm beauty-api-prod
        echo "✅ Container stopped"
        ;;
    
    logs)
        echo ""
        echo "📋 Container logs:"
        docker logs beauty-api-prod -f
        ;;
    
    status)
        echo ""
        echo "📊 Container Status:"
        docker ps -a --filter "name=beauty-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    
    test)
        echo ""
        echo "🧪 Testing API..."
        echo ""
        echo "GET /health:"
        curl -s http://localhost:8000/health | python3 -m json.tool || echo "❌ Health check failed"
        echo ""
        echo "GET /:"
        curl -s http://localhost:8000/ | python3 -m json.tool || echo "❌ Root endpoint failed"
        ;;
    
    clean)
        echo ""
        echo "🧹 Cleaning up..."
        docker rm -f beauty-api-prod 2>/dev/null || true
        docker rmi beauty-api:latest 2>/dev/null || true
        echo "✅ Cleanup complete"
        ;;
    
    *)
        echo ""
        echo "Usage: ./deploy.sh [command]"
        echo ""
        echo "Commands:"
        echo "  build    - Build Docker image"
        echo "  run      - Start container (port 8000)"
        echo "  stop     - Stop container"
        echo "  logs     - Show container logs"
        echo "  status   - Check container status"
        echo "  test     - Test API endpoints"
        echo "  clean    - Remove container & image"
        echo "  help     - Show this message"
        echo ""
        echo "Example workflow:"
        echo "  ./deploy.sh build"
        echo "  ./deploy.sh run"
        echo "  ./deploy.sh test"
        echo "  ./deploy.sh logs"
        echo "  ./deploy.sh stop"
        ;;
esac
