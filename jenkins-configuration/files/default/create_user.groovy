import hudson.model.Hudson;
import hudson.security.GlobalMatrixAuthorizationStrategy;
import hudson.security.HudsonPrivateSecurityRealm;

if(args.length != 3) {
  println("must specify the user, password, and role");
  System.exit(1);
} else {
  user = args[0];
  password = args[1];

  if (args[2] == "read") {
    role = Hudson.READ
  } else if (args[2] == "admin") {
    role = Hudson.ADMINISTER
  } else {
    println "${role} is an invalid role, defaulting to read-only."
    role = Hudson.READ
  }
} 


def constructMatrixAuthorizationStrategy(user, role) {
  authzStrategy = new GlobalMatrixAuthorizationStrategy();
  authzStrategy.add(role, user);
  return authzStrategy;
}

def configurePrivateSecurityRealm(user, password) {
  doNotAllowSignup = false;
  hudsonPrivateSecurityRealm = new HudsonPrivateSecurityRealm(doNotAllowSignup);

  hudsonPrivateSecurityRealm.createAccount(user, password)

  Hudson.instance.setSecurityRealm(hudsonPrivateSecurityRealm);
  println "Successfully set security realm to Hudson Private Realm without ability to signup";
}

authzStrategy = Hudson.instance.getAuthorizationStrategy();
if(!authzStrategy.getClass().equals(GlobalMatrixAuthorizationStrategy.class)) {
  matrixAuthzStrategy = constructMatrixAuthorizationStrategy(user, role);
  Hudson.instance.setAuthorizationStrategy(matrixAuthzStrategy);
  
  configurePrivateSecurityRealm(user, password);

  Hudson.instance.save();
}
else {
  //test deeper?
}
