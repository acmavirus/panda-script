<?php
/**
 * Panda Script v2.2 - Simple Webhook Listener
 * Place this in /var/www/domain/public/panda-webhook.php
 */

$secret = "YOUR_PANDA_SECRET"; // Should be passed/configured
$domain = "YOUR_DOMAIN";

$headers = getallheaders();
$signature = $headers['X-Hub-Signature-256'] ?? '';

if (!$signature) {
    http_response_code(403);
    die("No signature");
}

$payload = file_get_contents('php://input');
$expected_signature = 'sha256=' . hash_hmac('sha256', $payload, $secret);

if (!hash_equals($expected_signature, $signature)) {
    http_response_code(403);
    die("Invalid signature");
}

// Trigger Panda Script Deploy
// Note: This requires the web user (www-data) to have sudo access to /usr/local/bin/panda
// Or a specialized sudoers entry
$output = shell_exec("sudo /usr/local/bin/panda deploy $domain 2>&1");

file_put_contents("panda-deploy.log", "[" . date('Y-m-d H:i:s') . "] \n" . $output, FILE_APPEND);

echo "Deployment triggered for $domain\n";
echo "Result:\n$output";
?>
