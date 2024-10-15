# Notes
Living doc, used to track observations and improvements for each project component. 



### config/settings.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### core/cti.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### core/extract.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### handlers/file.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### handlers/input.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### handlers/presentation.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### nav/navcontroller.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/banner.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/encryption.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/file.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/history.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/keybindings.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### **Loader.py**
<details> 

## Notes
- The ACLoader uses lazy loading for improved performance
- The MITRELoader is currently using a third-party library and may need optimization
- The OCTILoader is marked as a dummy class and needs further development

##

## Observations

1. ACLoader:
   - Uses lazy loading for the attack_contr property
   - Loads data from three directories: ac_software_dir, ac_group_dir, and ac_ttp_dir
   - Includes performance logging using the rich library
   - Provides methods to filter objects by type (ttp, group, software, mitigation, tactic)

2. MITRELoader:
   - Uses the mitreattack.stix20 library for data handling
   - Implements lazy initialization with the _ensure_initialized method
   - Provides methods for retrieving specific data types and relationships

3. OCTILoader:
   - Marked as a dummy class, indicating it needs further development
   - Structure similar to ACLoader, but specific to OCTI data
   - Includes methods for filtering various OCTI object types

##

## Potential Improvements
1. Implement error handling for file reading operations
2. Optimize the data loading process, especially for large datasets
3. Add more detailed filtering methods
4. Implement a caching mechanism to improve performance on subsequent loads
5. Refactor MITRELoader to reduce dependency on third-party library
6. Complete the implementation of OCTILoader

For detailed function descriptions, refer to the Function Index.
</details>


##

### utils/logger.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/messages.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/metrics.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/stix.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### utils/validator.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### menu.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### prompts.yaml
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### settings.py
<details>

### Notes

### Observations

### Potential Improvements

</details>

##

### settings.yaml
<details>

### Notes

### Observations

### Potential Improvements

</details>

##