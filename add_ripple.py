import re

with open("Beanstalk/Beanstalk/FeedView.swift", "r") as f:
    content = f.read()

pattern1 = r'\.clipShape\(RoundedRectangle\(cornerRadius: 42, style: \.continuous\)\)\s*\.overlay\(RoundedRectangle\(cornerRadius: 42, style: \.continuous\)\.stroke\(Color\(red: 223/255, green: 223/255, blue: 223/255\), lineWidth: 0\.5\)\)\s*\.scaleEffect\(x: c2\.scaleX, y: c2\.scaleY\)'

replacement1 = """.clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 2))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
                )
                .background(
                    TouchLocatingView { location in
                        if !isPressed && frontCardIndex == 2 {
                            touchLocation = location
                        }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 42, style: .continuous).stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5))
                .scaleEffect(x: c2.scaleX, y: c2.scaleY)"""

pattern2 = r'\.clipShape\(RoundedRectangle\(cornerRadius: 42, style: \.continuous\)\)\s*\.overlay\(RoundedRectangle\(cornerRadius: 42, style: \.continuous\)\.stroke\(Color\(red: 223/255, green: 223/255, blue: 223/255\), lineWidth: 0\.5\)\)\s*\.scaleEffect\(x: c1\.scaleX, y: c1\.scaleY\)'

replacement2 = """.clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 1))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
                )
                .background(
                    TouchLocatingView { location in
                        if !isPressed && frontCardIndex == 1 {
                            touchLocation = location
                        }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 42, style: .continuous).stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5))
                .scaleEffect(x: c1.scaleX, y: c1.scaleY)"""

pattern0 = r'\.clipShape\(RoundedRectangle\(cornerRadius: 42, style: \.continuous\)\)\s*\.overlay\(\s*RoundedRectangle\(cornerRadius: 42, style: \.continuous\)\s*\.stroke\(Color\(red: 223/255, green: 223/255, blue: 223/255\), lineWidth: 0\.5\)\s*\)\s*\.scaleEffect\(x: c0\.scaleX, y: c0\.scaleY\)'

replacement0 = """.clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 0))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
                )
                .background(
                    TouchLocatingView { location in
                        if !isPressed && frontCardIndex == 0 {
                            touchLocation = location
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5)
                )
                .scaleEffect(x: c0.scaleX, y: c0.scaleY)"""

content = re.sub(pattern1, replacement1, content)
content = re.sub(pattern2, replacement2, content)
content = re.sub(pattern0, replacement0, content)

with open("Beanstalk/Beanstalk/FeedView.swift", "w") as f:
    f.write(content)
