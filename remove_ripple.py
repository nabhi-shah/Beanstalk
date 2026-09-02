with open("Beanstalk/Beanstalk/FeedView.swift", "r") as f:
    content = f.read()

replacements = [
    """                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 2))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
                )""",
    """                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 1))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
                )""",
    """                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 0))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
                )"""
]

for rep in replacements:
    content = content.replace(rep, "")

with open("Beanstalk/Beanstalk/FeedView.swift", "w") as f:
    f.write(content)
