extends Control

func display_notification(title, desc):
		$v/quest_title.text = title
		$v/quest_desc.text = desc
		show()
