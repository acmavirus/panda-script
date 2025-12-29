<?php
// Create a new Redis instance with fallback
$redis = null;
if (class_exists('Redis')) {
    try {
        $redis = new Redis();
        $redis->connect('127.0.0.1', 6379);
    } catch (Exception $e) {
        $redis = null;
    }
}

// Function to register a shortcode that includes a view file with Redis caching
function register_custom_shortcode($shortcode, $view_file) {
    global $redis; // Make the Redis instance available
    
    add_shortcode($shortcode, function($atts) use ($view_file, $redis) {
        // Generate cache key based on the shortcode and attributes
        $cacheKey = $shortcode;
        
        // Check for cached data (only if Redis is available)
        if ($redis) {
            $cachedData = $redis->get($cacheKey);
            if ($cachedData !== false) {
                return $cachedData;
            }
        }
        
        // Start output buffering
        ob_start();
        
        // Include the view file
        include(get_stylesheet_directory() . $view_file);
        
        // Get the buffered output
        $output = ob_get_clean();
        
        // Cache the output in Redis (expire after 1 hour)
        if ($redis) {
            $redis->setex($cacheKey, 3600, $output);
        }
        
        return $output; // Return the output
    });
}

// Register shortcodes
register_custom_shortcode('xsmb', '/view/kqxsmb-view.php');
register_custom_shortcode('xsmn', '/view/kqxsmn-view.php');
