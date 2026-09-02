import re

with open("Beanstalk/Beanstalk/FeedView.swift", "r") as f:
    content = f.read()

old_logo = """                Image("BeanstalkLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .matchedGeometryEffect(id: "logo", in: animationNamespace)
                    .padding(.top, 4)"""

new_logo = """                Image("BeanstalkLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .matchedGeometryEffect(id: "logo", in: animationNamespace)
                    .transition(.identity)
                    .padding(.top, 4)"""

content = content.replace(old_logo, new_logo)

with open("Beanstalk/Beanstalk/FeedView.swift", "w") as f:
    f.write(content)

