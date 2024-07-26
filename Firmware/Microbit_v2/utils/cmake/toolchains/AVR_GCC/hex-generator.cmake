add_custom_command(
    OUTPUT "${PROJECT_SOURCE_DIR}/${codal.output_folder}/${device.device}.hex"
    COMMAND "${AVR_OBJCOPY}" -O ihex "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${device.device}" "${PROJECT_SOURCE_DIR}/${codal.output_folder}/${device.device}.hex"
    DEPENDS  ${device.device}
    COMMENT "converting to hex file."
)

#specify a dependency on the elf file so that hex is automatically rebuilt when elf is changed.
add_custom_target(${device.device}_hex ALL DEPENDS "${PROJECT_SOURCE_DIR}/${codal.output_folder}/${device.device}.hex")
