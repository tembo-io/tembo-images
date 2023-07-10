FROM quay.io/tembo/tembo-pg-cnpg:f857ab0

USER root

# Dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    lsb-release \
    python3 \
    python3-pip \
    tzdata \
    sudo \
    cmake \
    libpq-dev \
    libclang-dev \
    wget \
    git \
    gnupg \
    lsb-release

# PL Python
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-plpython3-15

# PostgresML
RUN echo "deb [trusted=yes] https://apt.postgresml.org $(lsb_release -cs) main" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y postgresql-pgml-15=2.7.0

# pg vector
RUN trunk install pgvector

RUN pip3 install -r \
    accelerate==0.20.3 \
    auto-gptq==0.2.2 \
    ctransformers==0.2.8 \
    datasets==2.13.0 \
    deepspeed==0.9.4 \
    huggingface-hub==0.15.1 \
    InstructorEmbedding==1.0.1 \
    lightgbm==3.3.5 \
    orjson==3.9.1 \
    pandas==2.0.2 \
    rich==13.4.2 \
    rouge==1.0.1 \
    sacrebleu==2.3.1 \
    sacremoses==0.0.53 \
    scikit-learn==1.2.2 \
    sentencepiece==0.1.99 \
    sentence-transformers==2.2.2 \
    torch==2.0.1 \
    torchaudio==2.0.2 \
    torchvision==0.15.2 \
    tqdm==4.65.0 \
    transformers==4.30.2 \
    xgboost==1.7.5 \
    langchain==0.0.202 \
    einops==0.6.1

USER postgres
