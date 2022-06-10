# Procedure to clean-up data
1. Remove tests made by PIs [manual]
    - Usually participants names like `a`, `b`, `test`, `<PI Name>`, etc.
2. Replace user_id by their participant id in the private key (Google Sheet) to anonymize results
3. Remove trailing commas at the end of the line when present
4. Run `./clean_timeouts.py` to add tasks missed by taskset timeout. [automatic]
5. You have a dataset.

## Appending new data
For new data, follow the above steps and append the resulting rows to the main data file.