# Big_Data_amazon

# Amazon Product Reviews Analysis

A collaborative big data analysis project for the INF2006 Cloud Computing & Big Data course.

## Project Overview

This project analyzes the Amazon Product Reviews dataset to identify trends, sentiment patterns, and product features using Hadoop and Spark.

## Environment Setup

This project uses Docker and Docker Compose to create a consistent development environment across all team members' machines.

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Git](https://git-scm.com/downloads)

### Getting Started

1. Clone the repository:
   ```bash
   git clone 
   cd amazon-reviews-analysis
   ```

2. Start the Hadoop environment:
   ```bash
   docker-compose up -d
   ```

3. Load data into HDFS:
   ```bash
   chmod +x docker/*.sh
   ./docker/load-data.sh
   ```

4. Access the services:
   - HDFS UI: http://localhost:9870
   - YARN UI: http://localhost:8088
   - Spark Master: http://localhost:8080
   - Jupyter Lab: http://localhost:8888

### Stopping the Environment

```bash
docker-compose down
```

To preserve the HDFS data between restarts, use:
```bash
docker-compose stop
```

## Team Workflow

### Git Workflow

1. **Branch for features**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Commit changes**:
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

3. **Push changes**:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create Pull Request** on GitHub for review

5. **Merge after approval**

### Data Sharing

- Place small sample data in the `data/` directory
- For large datasets, share download instructions
- Use the `.gitignore` file to exclude large data files from the repository

### Code Organization

- **MapReduce Jobs**: `src/mapreduce/`
- **Spark Scripts**: `src/spark/`
- **Visualization Code**: `src/visualization/`
- **Jupyter Notebooks**: `notebooks/`
- **Results**: `results/`

## Running Analysis Jobs

### MapReduce Jobs

1. Compile the MapReduce Java code:
   ```bash
   docker exec -it namenode bash
   cd /src/mapreduce
   javac -cp $(hadoop classpath) ReviewRatingAnalysis.java
   jar cvf ReviewRatingAnalysis.jar *.class
   ```

2. Run the MapReduce job:
   ```bash
   hadoop jar ReviewRatingAnalysis.jar ReviewRatingAnalysis /user/hadoop/amazon_reviews/raw/amazon_sample.json /user/hadoop/amazon_reviews/results/rating_analysis
   ```

### Spark Jobs

Run a Spark job:
```bash
docker exec -it spark-master spark-submit --master spark://spark-master:7077 /src/spark/sentiment_analysis.py
```

## Interactive Analysis

Use Jupyter notebooks for interactive analysis and visualization:
1. Access Jupyter Lab at http://localhost:8888
2. Open the `notebooks/amazon_reviews_analysis.ipynb` notebook
3. Execute the cells to analyze the data

## Troubleshooting

### Common Issues

1. **HDFS Permission Issues**:
   ```bash
   docker exec -it namenode hdfs dfs -chmod -R 777 /user
   ```

2. **Container Not Starting**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

3. **HDFS Safe Mode**:
   ```bash
   docker exec -it namenode hdfs dfsadmin -safemode leave
   ```

## Team Responsibilities

- **Team Member 1**: Data ingestion and HDFS storage
- **Team Member 2**: MapReduce implementation and data processing
- **Team Member 3**: Spark analysis and visualization
- **Team Member 4**: Report writing and presentation

## Project Timeline

- **Week 1**: Environment setup and data collection
- **Week 2**: Data preprocessing and initial analysis
- **Week 3**: Advanced analysis and visualization
- **Week 4**: Finalize results and prepare report

## Resources

- [Hadoop Documentation](https://hadoop.apache.org/docs/r3.2.1/)
- [Spark Documentation](https://spark.apache.org/docs/3.1.1/)
- [Amazon Reviews Dataset](https://s3.amazonaws.com/amazon-reviews-pds/readme.html)