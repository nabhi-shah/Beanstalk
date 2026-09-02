with open("Beanstalk/Beanstalk/OnboardingView.swift", "r") as f:
    content = f.read()

old_onNext = """                                onNext: {
                                    appState = .feed
                                }"""

new_onNext = """                                onNext: {
                                    // Let the ripple effect play for 0.4s
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        appState = .loading
                                    }
                                }"""

content = content.replace(old_onNext, new_onNext)

with open("Beanstalk/Beanstalk/OnboardingView.swift", "w") as f:
    f.write(content)

