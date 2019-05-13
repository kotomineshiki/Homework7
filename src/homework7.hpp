#ifndef __PLAYGROUND__
#define __PLAYGROUND__

#include <glad/glad.h>   // for glad
#include <GLFW/glfw3.h>  // for glfw

#include <cmath>
#include <vector>
#include <algorithm>

void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void mouse_callback(GLFWwindow* window, double xpos, double ypos);
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
void ProcessInput(GLFWwindow *window);

void renderScene(GLuint shader_program);
void renderCube();
void renderQuad();

#endif