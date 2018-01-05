INSERT INTO `location_tag` (`location_tag_id`, `name`, `creator`, `date_created`, `retired`, `uuid`) VALUES ('1', 'Workstation Location', '1', NOW(), '0', '20a1c285-51e3-11e3-8fcd-003018acf05d');

INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) VALUES ('721', '1');
