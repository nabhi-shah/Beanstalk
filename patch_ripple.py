with open("Beanstalk/Beanstalk/FeedView.swift", "r") as f:
    content = f.read()

old_tap = """        .onTapGesture {
            if !isExpanded {
                onToggle()
            }
        }"""

new_tap = """        .onTapGesture {
            if !isExpanded {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
                onToggle()
            }
        }"""

content = content.replace(old_tap, new_tap)

with open("Beanstalk/Beanstalk/FeedView.swift", "w") as f:
    f.write(content)

