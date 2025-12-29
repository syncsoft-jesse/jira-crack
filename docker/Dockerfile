FROM atlassian/jira-software:latest

USER root

# Add agent file
COPY atlassian-agent.jar /opt/atlassian/jira/

# Add agent to env
RUN echo 'export CATALINA_OPTS="-javaagent:/opt/atlassian/jira/atlassian-agent.jar ${CATALINA_OPTS}"' >> /opt/atlassian/jira/bin/setenv.sh

USER jira
