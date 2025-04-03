/** Kai jun data cleaning and preprocessing */ 
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashSet;
import java.util.Set;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

public class ReviewAnalysis {

    /**
     * Mapper for processing JSON input
     * Each input record is already in JSON format
     */
    public static class JsonMapper extends Mapper<LongWritable, Text, Text, Text> {
        
        private JSONParser parser = new JSONParser();
        private Text productIdKey = new Text();
        private Text jsonValue = new Text();
        
        @Override
        public void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
            String line = value.toString().trim();
            if (line.isEmpty()) {
                return; // Skip empty lines
            }
            
            try {
                // Parse the JSON input
                JSONObject json = (JSONObject) parser.parse(line);
                
                // Extract the product ID
                String productId = "unknown";
                if (json.containsKey("product/productId")) {
                    productId = json.get("product/productId").toString();
                }
                
                // Output with product ID as key, original JSON as value
                productIdKey.set(productId);
                jsonValue.set(line);
                context.write(productIdKey, jsonValue);
                
            } catch (Exception e) {
                // Log malformed JSON
                context.getCounter("JsonMapper", "MalformedJson").increment(1);
            }
        }
    }

    /**
     * Reducer that filters duplicates and records with unknown values
     */
    public static class FilterReducer extends Reducer<Text, Text, Text, Text> {
        
        private Set<String> duplicates = new HashSet<>();
        private Text emptyKey = new Text();
        private JSONParser parser = new JSONParser();
        
        @Override
        protected void setup(Context context) throws IOException, InterruptedException {
            // Load duplicates file if specified
            Configuration conf = context.getConfiguration();
            String duplicatesFilePath = conf.get("duplicates.file");
            
            if (duplicatesFilePath != null && !duplicatesFilePath.isEmpty()) {
                loadDuplicatesFile(context, duplicatesFilePath);
            } else {
                System.out.println("No duplicates file specified - duplicate filtering disabled");
            }
        }
        
        /**
         * More efficient method to load duplicates file
         */
        private void loadDuplicatesFile(Context context, String duplicatesFilePath) throws IOException {
            long startTime = System.currentTimeMillis();
            Path path = new Path(duplicatesFilePath);
            FileSystem fs = FileSystem.get(context.getConfiguration());
            
            if (!fs.exists(path)) {
                System.err.println("WARNING: Duplicates file not found: " + duplicatesFilePath);
                context.getCounter("FilterReducer", "DuplicatesFileNotFound").increment(1);
                return;
            }
            
            int pairsProcessed = 0;
            
            try (FSDataInputStream in = fs.open(path);
                 BufferedReader reader = new BufferedReader(new InputStreamReader(in), 8192)) { // Larger buffer
                
                String line;
                // Process the file in chunks for better performance
                StringBuilder buffer = new StringBuilder(1024 * 1024); // 1MB buffer
                char[] charBuffer = new char[8192];
                int charsRead;
                
                while ((charsRead = reader.read(charBuffer)) != -1) {
                    buffer.append(charBuffer, 0, charsRead);
                    
                    // Process complete lines in the buffer
                    int newlinePos;
                    int startPos = 0;
                    while ((newlinePos = buffer.indexOf("\n", startPos)) != -1) {
                        // Extract a complete line
                        String completeLine = buffer.substring(startPos, newlinePos).trim();
                        
                        // Process the line if it's not empty
                        if (!completeLine.isEmpty()) {
                            processDuplicateLine(completeLine);
                            pairsProcessed++;
                        }
                        
                        startPos = newlinePos + 1;
                    }
                    
                    // Keep remaining partial line in buffer
                    if (startPos < buffer.length()) {
                        buffer.delete(0, startPos);
                    } else {
                        buffer.setLength(0);
                    }
                }
                
                // Process any remaining data in the buffer
                if (buffer.length() > 0) {
                    String completeLine = buffer.toString().trim();
                    if (!completeLine.isEmpty()) {
                        processDuplicateLine(completeLine);
                        pairsProcessed++;
                    }
                }
            }
            
            long loadTime = System.currentTimeMillis() - startTime;
            
            // Log summary
            System.out.println("Duplicates file processed efficiently: " + duplicatesFilePath);
            System.out.println("  - Duplicate pairs processed: " + pairsProcessed);
            System.out.println("  - Product IDs to filter: " + duplicates.size());
            System.out.println("  - Load time: " + loadTime + "ms");
            
            context.getCounter("FilterReducer", "DuplicatePairsProcessed").increment(pairsProcessed);
            context.getCounter("FilterReducer", "ProductIDsToFilter").increment(duplicates.size());
        }
        
        /**
         * Process a single line from the duplicates file - optimized version
         */
        private void processDuplicateLine(String line) {
            // Faster version with substring operations instead of regex
            int andPos = line.indexOf(" and ");
            if (andPos > 0) {
                String firstPart = line.substring(0, andPos).trim();
                String secondPart = line.substring(andPos + 5); // Skip " and "
                
                int havePos = secondPart.indexOf(" have ");
                if (havePos > 0) {
                    String secondProductId = secondPart.substring(0, havePos).trim();
                    // Add the second product ID to our duplicates set
                    duplicates.add(secondProductId);
                }
            }
        }
        
        @Override
        public void reduce(Text key, Iterable<Text> values, Context context) 
                throws IOException, InterruptedException {
            
            // Skip if product ID is in the duplicates set
            if (duplicates.contains(key.toString())) {
                context.getCounter("FilterReducer", "DuplicateProductsSkipped").increment(1);
                return;
            }
            
            // Process each value
            for (Text value : values) {
                try {
                    String jsonStr = value.toString();
                    JSONObject json = (JSONObject) parser.parse(jsonStr);
                    
                    // Check for "unknown" values
                    boolean hasUnknown = false;
                    for (Object keyObj : json.keySet()) {
                        Object valObj = json.get(keyObj);
                        if (valObj instanceof String && 
                            ((String) valObj).equalsIgnoreCase("unknown")) {
                            hasUnknown = true;
                            context.getCounter("FilterReducer", "UnknownValuesSkipped").increment(1);
                            break;
                        }
                    }
                    
                    // Output only if no "unknown" values
                    if (!hasUnknown) {
                        emptyKey.set("");
                        context.write(emptyKey, value);
                        context.getCounter("FilterReducer", "RecordsOutput").increment(1);
                    }
                    
                } catch (Exception e) {
                    context.getCounter("FilterReducer", "ParseErrors").increment(1);
                }
            }
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 2 || args.length > 3) {
            System.err.println("Usage: ReviewAnalysis <input path> <output path> [duplicates file]");
            System.exit(-1);
        }
        
        String inputPath = args[0];
        String outputPath = args[1];
        String duplicatesPath = args.length > 2 ? args[2] : null;
        
        System.out.println("Input file path: " + inputPath);
        System.out.println("Output directory: " + outputPath);
        if (duplicatesPath != null) {
            System.out.println("Duplicates file: " + duplicatesPath);
        }
        
        Configuration conf = new Configuration();
        if (duplicatesPath != null) {
            conf.set("duplicates.file", duplicatesPath);
        }
        
        Job job = Job.getInstance(conf, "Amazon Review JSON Processing");
        job.setJarByClass(ReviewAnalysis.class);
        
        // Set mapper and reducer
        job.setMapperClass(JsonMapper.class);
        job.setReducerClass(FilterReducer.class);
        
        // Set output types
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        // Set input and output paths
        FileInputFormat.addInputPath(job, new Path(inputPath));
        FileOutputFormat.setOutputPath(job, new Path(outputPath));
        
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}