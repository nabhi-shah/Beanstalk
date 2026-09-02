with open("Beanstalk/Beanstalk/MainCoordinator.swift", "r") as f:
    content = f.read()

content = content.replace("allowsHitTesting(appState == .onboarding || appState == .feed)", "allowsHitTesting(appState == .onboarding)")

with open("Beanstalk/Beanstalk/MainCoordinator.swift", "w") as f:
    f.write(content)

