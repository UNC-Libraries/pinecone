Pinecone (Temporary Preservation Storage)
========

Performs basic preservation activities upon bagit bags located within a given set of watched preservation locations.  These activities include:
* Validation upon receipt of bag
  * Bags are checked for:
    * completeness - no unexpected or missing files
    * consistency - checksums of files in the payload match those recorded in the bag manifest
  * If a bag is invalid, an error report email is sent out to administrators and content owners who are locally configured to receive notifications for that location.
* Replication of bags
  * After bags have been validated the first time, they are replicated to a configured replica location using rsync.
  * After replication completes, the bag in the replica location is 0xum validated (total filesize and file count)
  * If replication fails, administrators are emailed.
* Periodic validation of bags - After a configured number of days since the last validation, bags (and their replicas) will be validated again.
  * If validation fails, administrators and content owners will be notified.

All actions and their outcomes are recorded to a central log.  

Application Configuration
==========
Requires the configuration of a PINECONE_DATA environment variable, which points to a directory where configuration and data should stored.

config.yaml
-----------
Primary configuration for the application.  Includes:
* admin_email - A list of administrator email addresses who should be contacted for all errors
* from_email - Sender address for error report emails
* preservation_locations - List of directories containing bags upon which preservation activities will be performed.
* replica_path - Path to the directory where replicas will be written.
* activity_log - Configuration of the activity log, including severity level, name of the log file (to log to STDIO provide ~ as the filename), the size per log file and the number of log files to retain.

pinecone.db
-----------
Sqlite3 database which records registration and validation information about bags being monitored by pinecone.

Location Configuration
============
Each location registered as a preservation location should contain a "tps-info.yaml" file to mark it as a preservation location and to provide location specific configuration/documentation.  This file contains:

* name - Identifier for the location, which must be unique.  It will be used as the name of the base directory containing bags from this location during replication.
* contacts - A list of email addresses for people that should be contacted with reports for objects within this location.