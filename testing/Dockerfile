# AI Testing Environment
# Dedicated container for running AI testing frameworks with proper dependencies

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast Python package management
RUN pip install uv

# Create app structure
RUN mkdir -p /app/app
RUN mkdir -p /app/testing_frameworks
RUN mkdir -p /app/results/websocket_results
RUN mkdir -p /app/results/api_consistent_results  
RUN mkdir -p /app/results/classic_results

# Copy backend source code (needed for imports)
COPY backend/app /app/app
COPY backend/pyproject.toml /app/
COPY backend/uv.lock /app/

# Copy testing frameworks  
COPY testing/testing_frameworks /app/testing_frameworks

# Install core dependencies
RUN cd /app && uv sync --frozen

# Install additional testing dependencies
RUN cd /app && uv add websockets aiohttp requests

# Make testing scripts executable
RUN chmod +x /app/testing_frameworks/*.py

# Set environment variables
ENV PYTHONPATH=/app
ENV BACKEND_HOST=backend
ENV BACKEND_PORT=8000
ENV BACKEND_WS_URL=ws://backend:8000

# Create a run script for easy testing
RUN echo '#!/bin/bash\n\
echo "🐳 Mexican Train AI Testing Environment"\n\
echo "🔗 Backend: $BACKEND_WS_URL"\n\
echo ""\n\
echo "Available testing frameworks:"\n\
echo "  📡 WebSocket:      python /app/testing_frameworks/websocket_ai_test.py"\n\
echo "  🔄 API-Consistent: python /app/testing_frameworks/api_consistent_test.py"\n\
echo "  🎯 Classic:        python /app/testing_frameworks/classic_ai_test.py"\n\
echo ""\n\
echo "Example commands:"\n\
echo "  python /app/testing_frameworks/websocket_ai_test.py list"\n\
echo "  python /app/testing_frameworks/websocket_ai_test.py match chain_strategist locomotive_legend"\n\
echo "  python /app/testing_frameworks/api_consistent_test.py batch chain_strategist locomotive_legend --count 5"\n\
echo ""\n\
exec bash "$@"\n\
' > /app/run.sh && chmod +x /app/run.sh

# Default command shows help
CMD ["/app/run.sh"]