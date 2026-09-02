with open("Beanstalk/Beanstalk/FeedView.swift", "r") as f:
    content = f.read()

old_button = """                        Image("PencilSimpleLine")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.textSecondary)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color.white.opacity(0.01)))
                            .contentShape(Circle())
                    }
                    .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.3)))
                    .background(
                        Circle().glassEffect(.regular.tint(Color.white.opacity(0.4)), in: .circle)
                    )"""

new_button = """                        Image("PencilSimpleLine")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.textSecondary)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color.white.opacity(0.01)))
                            .contentShape(Circle())
                    }
                    .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.3)))
                    .background(
                        Circle().fill(Color.white)
                    )"""

content = content.replace(old_button, new_button)

old_button_2 = """                            Image("PencilSimpleLine")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Color.white.opacity(0.01)))
                                .contentShape(Circle())
                        }
                        .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.3)))
                        .background(
                            Circle().glassEffect(.regular.tint(Color.white.opacity(0.4)), in: .circle)
                        )"""

new_button_2 = """                            Image("PencilSimpleLine")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Color.white.opacity(0.01)))
                                .contentShape(Circle())
                        }
                        .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.3)))
                        .background(
                            Circle().fill(Color.white)
                        )"""

content = content.replace(old_button_2, new_button_2)

with open("Beanstalk/Beanstalk/FeedView.swift", "w") as f:
    f.write(content)

