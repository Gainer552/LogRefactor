
                         LogRefactor

LogRefactor is a high-signal, noise-reduction and pattern-analysis
tool for Linux system logs. It ingests any plaintext log file,
extracts structural meaning, identifies recurring patterns, highlights
new/unseen entries, collapses severity levels, and presents the result
in a clean, color-coded tabular format.

This tool is purpose-built for engineers, analysts, and sysadmins who
need to quickly understand log behavior without sifting through
thousands of redundant lines.


                       Features Overview

• Automatic grouping of identical log lines.
• Line-frequency counting.
• Timestamp extraction.
• Detection of new / previously unseen log patterns.
• Color-coded output for readability.
• Clean table-based result format.
• Pattern grouping via structural normalization.
• PID-based aggregation.
• Process-level aggregation.
• Severity-level collapsing (INFO, WARN, ERR, CRIT).
• Human-friendly summaries.
• Output saved to an immutable .txt file in the current directory.


                     How LogRefactor Works

LogRefactor analyzes the provided log file in several stages:

1. Input Gathering
   The user is prompted to supply the path to any plaintext log file.

2. Pattern Normalization
   IP addresses, PIDs, and long numeric sequences are normalized and
   converted into placeholders to detect structural patterns.

3. Group Aggregation
   LogRefactor groups identical lines, counts occurrences, and
   extracts timestamps for each unique entry.

4. Severity Collapsing
   Known error and warning keywords are used to classify each line
   into human-readable severity buckets.

5. Process and PID Aggregation
   Process names and process IDs are tallied to help identify noisy or
   misbehaving components.

6. New Pattern Detection
   A persistent cache is used to track previously observed normalized
   log patterns. New unseen patterns are highlighted on every run.

7. Output Generation
   The final report is displayed in a color-coded table and saved as a
   timestamped .txt file. The script attempts to set the file
   immutable where permissions allow.


                     Usage Instructions

1. Ensure the script is executable: chmod +x logrefactor.sh

2. Run the script: ./logrefactor.sh

3. When prompted, enter the path to the log file you want to analyze.

4. After processing completes:
   • Results will display on screen. 
   • A report file named:
         log_reduced_output_YYYYMMDD_HHMMSS.txt
     will be saved in the current directory. 
   • If run as root, this output file will be made immutable
     using: chattr +i.


                     Recommended Log Inputs

LogRefactor can process any plaintext log file, but it is especially
useful with:

• /var/log/auth.log  
• /var/log/syslog  
• /var/log/messages  
• /var/log/nginx/error.log  
• /var/log/apache2/error.log  
• Application-specific logs  
• Custom debug logs  


                     Output File Structure

The output file includes:

• Header section.
• Grouped line table (count | timestamp | message). 
• Process aggregation table.
• PID aggregation table.
• New/unseen structural patterns.
• Final summary metrics.


                         Legal Disclaimer

LogRefactor is provided “as is” with no warranties expressed or
implied. The authors and contributors are not responsible for any
damages, data loss, system impact, or security issues resulting from
the use or misuse of this software. Users assume all responsibility for
testing, validating, and deploying this tool within their own systems.

This tool is intended solely for lawful, ethical log analysis and
administration of systems for which the user has authorization.

Unauthorized use on systems you do not own or administer may violate
local, federal, or international laws. Use responsibly.