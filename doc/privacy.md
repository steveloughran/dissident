## Privacy Policy

Dissident is a program which runs locally, talking only to Twitter via its Twitter APIs.

No other data leaves the machine running the program, and the only local data generated is the stdout log. Note that tweets received are logged there, which may be considered sensitive. And, as received tweets are not sanitized, you'd better not feed that log though a SQL parser or similar. The data must be considered malicious.

Twitter have their own privacy policy, which is beyond the scope of this document

