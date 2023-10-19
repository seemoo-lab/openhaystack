add_custom_command(
    OUTPUT "${PROJECT_SOURCE_DIR}/${codal.output_folder}/${device.device}.bin"
    COMMAND "${AVR_OBJCOPY}" -O binary "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${device.device}" "${PROJECT_SOURCE_DIR}/${codal.output_folder}/${device.device}.bin"
    DEPENDS  ${device.device}
    COMMENT "converting to bin file."
)

#specify a dependency on the elf file so that bin is automatically rebuilt when elf is changed.
add_custom_target(${device.device}_bin ALL DEPENDS "${PROJECT_SOURCE_DIR}/${codal.output_folder}/${device.device}.bin")
